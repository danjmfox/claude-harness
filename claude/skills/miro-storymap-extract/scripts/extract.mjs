import { readFileSync } from 'node:fs';

// Faithful JS port of tools/story-map/extract.py, adding the journey tier the
// Python flattens: it walks a Miro SVG export composing the <g> transform stack,
// reads <foreignObject> cards + free <text> labels, then reconstructs the board
// as journey -> step (column) -> swimlane -> card. Stdlib only; JSON to stdout.

// --- Affine transforms (2x3: a,b,c,d,e,f -> x' = a*x+c*y+e, y' = b*x+d*y+f) ---

const IDENTITY = [1, 0, 0, 1, 0, 0];

const compose = (A, B) => {
  const [a1, b1, c1, d1, e1, f1] = A;
  const [a2, b2, c2, d2, e2, f2] = B;
  return [
    a1 * a2 + c1 * b2,
    b1 * a2 + d1 * b2,
    a1 * c2 + c1 * d2,
    b1 * c2 + d1 * d2,
    a1 * e2 + c1 * f2 + e1,
    b1 * e2 + d1 * f2 + f1,
  ];
};

const apply = ([a, b, c, d, e, f], x, y) => [a * x + c * y + e, b * x + d * y + f];

const parseTransform = (s) => {
  let m = IDENTITY;
  for (const [, fn, rawArgs] of s.matchAll(/(matrix|translate|scale)\(([^)]*)\)/g)) {
    const nums = rawArgs.trim().split(/[ ,]+/).filter(Boolean).map(Number);
    let t;
    if (fn === 'matrix' && nums.length === 6) t = nums;
    else if (fn === 'translate' && nums.length) t = [1, 0, 0, 1, nums[0], nums.length > 1 ? nums[1] : 0];
    else if (fn === 'scale' && nums.length) t = [nums[0], 0, 0, nums.length > 1 ? nums[1] : nums[0], 0, 0];
    else continue;
    m = compose(m, t);
  }
  return m;
};

// --- Card text parsing ---

const STATUSES = [
  'In Progress', 'Ready for Test', 'Peer Review', 'To Do', 'To do',
  'Backlog', 'Released', 'Stopped', 'Blocked', 'Done',
];
const JIRA_RE = /\b[A-Z][A-Z0-9]+-\d+\b/;
const PR_RE = /#\d+/;
const reEsc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const attr = (attrs, name) => {
  const m = attrs.match(new RegExp(`\\b${name}="([^"]*)"`));
  return m ? m[1] : null;
};

const unescapeHtml = (s) =>
  s
    .replace(/&lt;/g, '<').replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"').replace(/&#0*39;|&apos;/g, "'").replace(/&nbsp;/g, ' ')
    .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, h) => String.fromCodePoint(parseInt(h, 16)))
    .replace(/&amp;/g, '&');

const cleanText = (inner) => {
  const noStyleScript = inner
    .replace(/<style\b[\s\S]*?<\/style>/g, ' ')
    .replace(/<script\b[\s\S]*?<\/script>/g, ' ');
  return unescapeHtml(noStyleScript.replace(/<[^>]+>/g, ' ')).replace(/\s+/g, ' ').trim();
};

const parseFields = (raw) => {
  const jira = raw.match(JIRA_RE);
  const pr = raw.match(PR_RE);
  const sha = raw.match(/\b[0-9a-f]{7,40}\b/);
  const status = STATUSES.find((s) => new RegExp(`\\b${reEsc(s)}\\b`).test(raw)) ?? '';
  let commitRef = '';
  if (sha) commitRef = pr ? `${sha[0]} (${pr[0]})` : sha[0];
  else if (pr) commitRef = pr[0];
  let title = raw.replace(/\s*[-–]\s*[0-9a-f]{7,40}.*$/, '');
  if (status) title = title.replace(new RegExp(`\\s*\\b${reEsc(status)}\\b.*$`), '');
  title = title.replace(/^[ \-–|]+|[ \-–|]+$/g, '');
  return { status, jira_key: jira ? jira[0] : '', commit_ref: commitRef, title };
};

// --- SVG walk: foreignObject -> card, free <text> -> label, composing transforms ---

const TAG_RE = /<(\/?)(g|foreignObject|text)\b([^>]*?)(\/?)>/gs;
const round1 = (v) => Number(v.toFixed(1));

const extractCards = (svg) => {
  const stack = [IDENTITY];
  const cards = [];
  const labels = [];
  for (const m of svg.matchAll(TAG_RE)) {
    const [full, closing, tag, attrs, selfclose] = m;
    if (tag === 'g') {
      if (closing) {
        if (stack.length > 1) stack.pop();
      } else if (!selfclose) {
        stack.push(compose(stack[stack.length - 1], parseTransform(attr(attrs, 'transform') ?? '')));
      }
      continue;
    }
    if (closing) continue;
    const start = m.index + full.length;
    const end = svg.indexOf(`</${tag}>`, start);
    const raw = cleanText(end !== -1 ? svg.slice(start, end) : '');
    if (!raw) continue;
    const [x, y] = apply(stack[stack.length - 1], Number(attr(attrs, 'x') ?? 0), Number(attr(attrs, 'y') ?? 0));
    if (tag === 'foreignObject') cards.push({ x: round1(x), y: round1(y), ...parseFields(raw), raw });
    else labels.push({ x: round1(x), y: round1(y), text: raw });
  }
  return { cards, labels };
};

// --- Layout: x-cluster steps into columns, group steps under journeys, band by swimlane ---

const cluster = (values, gap) => {
  const out = [];
  for (const v of [...values].sort((a, b) => a - b)) {
    const g = out[out.length - 1];
    if (g && v - g[g.length - 1] <= gap) g.push(v);
    else out.push([v]);
  }
  return out.map((g) => ({ centre: g.reduce((a, b) => a + b, 0) / g.length, members: g }));
};

const nearestIndex = (centres, v) =>
  centres.reduce((best, c, i) => (Math.abs(c - v) < Math.abs(centres[best] - v) ? i : best), 0);

const EMPTY = { journeys: [], swimlanes: [], cards: [], counts: { journeys: 0, steps: 0, swimlanes: 0, cards: 0 } };

const buildStructure = (cards, labels) => {
  if (!cards.length) return EMPTY;

  const xs = cards.map((c) => c.x);
  const xGap = Math.max(40, (Math.max(...xs) - Math.min(...xs)) / 200 || 40);

  // Rows are positional: row 1 = journeys, row 2 = steps, rows 3+ = stories.
  // Band by y with a fixed row gap — rows sit a constant distance apart and,
  // unlike columns, that spacing does not scale with board width.
  const ROW_GAP = 40;
  const yBands = cluster([...new Set(cards.map((c) => c.y))], ROW_GAP);
  const journeyYs = new Set(yBands[0]?.members ?? []);
  const stepYs = new Set(yBands[1]?.members ?? []);
  const journeyCards = cards.filter((c) => journeyYs.has(c.y));
  const stepCards = cards.filter((c) => stepYs.has(c.y));
  const dataCards = cards.filter((c) => !journeyYs.has(c.y) && !stepYs.has(c.y));

  // Steps are the columns.
  const stepCentres = cluster([...new Set(stepCards.map((c) => c.x))], xGap).map((c) => c.centre);
  const stepNames = stepCentres.map((centre, i) => {
    const owner = stepCards.find((c) => nearestIndex(stepCentres, c.x) === i);
    return owner ? owner.title || owner.raw : `step@${Math.round(centre)}`;
  });

  // Journeys group steps by x-span: each journey owns [its x, the next journey's x).
  const journeyDefs = journeyCards
    .slice()
    .sort((a, b) => a.x - b.x)
    .map((jc) => ({ name: jc.title || jc.raw, xStart: jc.x, steps: [] }));
  const journeyOf = (x) => {
    for (let i = journeyDefs.length - 1; i >= 0; i -= 1) if (x >= journeyDefs[i].xStart) return i;
    return journeyDefs.length ? 0 : -1;
  };
  stepCentres.forEach((centre, i) => {
    const ji = journeyOf(centre);
    if (ji >= 0) journeyDefs[ji].steps.push({ name: stepNames[i] });
  });

  // Swimlanes: non-numeric <text> labels below the header rows; a card joins the
  // last lane whose label sits at or above it.
  const stepY = yBands[1]?.centre ?? yBands[0]?.centre ?? 0;
  const lanes = labels
    .filter((l) => !/^\d+$/.test(l.text.trim()) && l.y > stepY + xGap)
    .sort((a, b) => a.y - b.y);
  const swimlaneOf = (y) => {
    let chosen = null;
    for (const l of lanes) if (l.y - 20 <= y) chosen = l;
    return chosen ? chosen.text : '(unbanded)';
  };

  const outCards = dataCards
    .slice()
    .sort((a, b) => a.y - b.y || a.x - b.x)
    .map((c) => {
      const ci = nearestIndex(stepCentres, c.x);
      const ji = journeyOf(stepCentres[ci] ?? c.x);
      return {
        journey: ji >= 0 ? journeyDefs[ji].name : '',
        step: stepNames[ci] ?? '',
        swimlane: swimlaneOf(c.y),
        title: c.title,
        jira_key: c.jira_key,
        commit_ref: c.commit_ref,
        status: c.status,
        x: c.x,
        y: c.y,
      };
    });

  return {
    journeys: journeyDefs.map((j) => ({ name: j.name, steps: j.steps })),
    swimlanes: lanes.map((l) => l.text),
    cards: outCards,
    counts: {
      journeys: journeyDefs.length,
      steps: stepCentres.length,
      swimlanes: lanes.length,
      cards: outCards.length,
    },
  };
};

// --- Imperative shell ---

const svgPath = process.argv[2];
if (!svgPath) {
  process.stderr.write('usage: extract.mjs <path-to-svg>\n');
  process.exit(2);
}
const { cards, labels } = extractCards(readFileSync(svgPath, 'utf8'));
process.stdout.write(`${JSON.stringify(buildStructure(cards, labels), null, 2)}\n`);
