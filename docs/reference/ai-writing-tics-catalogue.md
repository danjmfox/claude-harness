# Reference: AI/LLM Writing Tics Catalogue

**Date**: 2026-09-25 | **Researcher**: nw-researcher (Nova) | **Confidence**: Mixed (per-entry) | **Sources**: 38 examined, 28 cited

Extends `docs/research/writing-style/human-friendly-ai-writing-guidance.md` Findings 6-9. See that file for em-dash overuse, the "it's not just X, it's Y" antithesis construction, vocabulary inflation (delve/underscore/intricate/meticulous/boast), the named "AI slop" taxonomy (three-item parallelism triads, vapid openers, mid-sentence rhetorical questions, sentence-length monotony, generic analogies, surface-coherence-masking-filler), and RLHF-driven sycophancy/hedging mechanisms. This catalogue covers everything else documented in the literature as of 2026-09-25.

Each entry uses a fixed field order (Name / Example / Likely Mechanism / Source / Confidence), reused verbatim for scannability. "Likely Mechanism" separates the _causal_ claim (why this happens: training data, RLHF, human-rater preference) from the _observational_ claim (that the pattern occurs); these frequently carry different evidentiary strength and are flagged as such within each entry.

Confidence key: **High** = 3+ high-reputation/academic sources agree, no contradictions. **Medium** = 2+ sources agree, or 3+ medium-trust sources cross-referenced per the medium-trust tier rule, or one authoritative academic source with no independent replication yet. **Low** = single source, practitioner-only, or unresolved contradictions, explicitly still included per this catalogue's "documented gap is a finding" mandate.

---

## Catalogue

### 1. Stock Transition/Connective Words

**Example**: "Moreover, this approach offers significant benefits. Furthermore, it is worth noting that... In conclusion, ..."
**Likely Mechanism**: Observational claim (well-documented): LLMs default to a narrow set of "statistically safe" connective words because next-token prediction rewards unsurprising, high-frequency continuations. Causal-mechanism claim (RLHF amplification of "articulate-sounding" connectives) is asserted by practitioner sources but not independently peer-reviewed for this specific word class. It extends the RLHF-amplification mechanism documented for em-dashes and vocabulary in Findings 6-7 (em-dash overuse, vocabulary inflation) of the linked research doc, applied here to connective words without separate proof.
**Source**: [Originality.AI — Obvious ChatGPT Sayings](https://originality.ai/blog/obvious-chatgpt-sayings); [Blake Stockton — Don't Write Like AI](https://www.blakestockton.com/p/red-flag-phrases); [Jodie Cook — Ban List](https://www.jodiecook.com/ban-list/) (all medium-trust practitioner, 3-source cross-referenced per medium-trust tier rule)
**Confidence**: Medium (3 independent practitioner sources converge; no academic corpus study isolating this specific word class was found, per Knowledge Gap 1)

### 2. Formulaic Openers/Closers ("In today's...", "In the ever-evolving landscape of...")

**Example**: "In today's fast-paced digital world, businesses must navigate an ever-evolving landscape..."
**Likely Mechanism**: Observational: identified independently across every practitioner source found as one of the single most recognizable AI tells. Causal: same next-token-safety mechanism as Entry 1; not independently studied via formal corpus analysis for this exact phrase.
**Source**: [Originality.AI](https://originality.ai/blog/obvious-chatgpt-sayings); [Metric37 — Common AI Words and Phrases](https://metric37.com/blog/common-ai-words-and-phrases); [SynkrLAB — ChatGPT's Most Overused Words and Phrases](https://synkrlab.com/chatgpts-most-overused-words-and-phrases/); [Turn Off Communications — ChatGPT's Language Tics Field Guide](https://www.turn-off-communications.com/blog/chatgpts-language-tics-a-field-guide-2025) (4 independent medium-trust practitioner sources, non-circular)
**Confidence**: Medium (broad practitioner convergence; no peer-reviewed corpus study found isolating this exact phrase pattern, per Knowledge Gap 1)

### 3. Corporate/Elevated Verb and Metaphor Overuse

**Example**: "leverage," "unlock," "elevate," "foster," "navigate," "streamline," "harness," "tapestry," "testament to," "game-changer," "realm," "cornerstone," "beacon," "embark," "pivotal," "robust," "nuanced," "multifaceted"
**Likely Mechanism**: This is the _same_ excess-vocabulary phenomenon and mechanism as Finding 7 (vocabulary inflation, peer-reviewed) in the linked research doc, backed by peer-reviewed corpus evidence such as Science Advances sciadv.adt3813. The word list here is new; the mechanism is the one Finding 7 (vocabulary inflation) already establishes. This entry catalogues the additional words the literature documents beyond delve/underscore/intricate/meticulous/boast.
**Source**: [arXiv:2412.11385 — Why Does ChatGPT "Delve" So Much?](https://arxiv.org/pdf/2412.11385) (academic, extends the same excess-vocabulary methodology to a broader word list); [Medium — Jake Orlowitz, "Delving into the load-bearing tapestry of AI's overused words"](https://medium.com/@jakeorlowitz/delving-into-the-load-bearing-tapestry-of-ais-overused-words-a2a0024cee9a); [SlopDetector — The AI Words List](https://slopdetector.org/blog/ai-words-list) (commercial AI-detection vendor — bias flag: has commercial interest in the "AI detection" framing; corroborating only, not sole source)
**Confidence**: High for the general phenomenon (inherits Finding 7's (vocabulary inflation) academic backing); Medium for this specific extended word list (1 academic source generalizing the method + 2 corroborating practitioner sources, one with a noted commercial-interest bias)

### 4. Title-Case-Everywhere Heading Habit

**Example**: "## Understanding The Core Principles Of Effective Communication" (every word capitalized, including articles/prepositions)
**Likely Mechanism**: Practitioner-hypothesized: training data over-weighted toward headline/SEO/press-release conventions, where title case is the norm, biases heading generation toward that register even in body prose. No formal study located confirming this causal path.
**Source**: [Medium — Deborah MT, "Title Case is your accidental AI tell"](https://deborahmt.medium.com/title-case-is-your-accidental-ai-tell-2e83bbe46fe3)
**Confidence**: Low (single practitioner source; explicitly documented as a gap rather than omitted, since no corroborating second source was found in this search pass)

### 5. List-itis / Bold-Header-Per-Bullet Formatting

**Example**: A response to a simple question rendered as "- **Key Point 1**: description... - **Key Point 2**: description..." rather than connected prose; every list item opens with a bolded lead phrase.
**Likely Mechanism**: Academically documented as markdown-training leakage. Models trained heavily on markdown-formatted text default to markdown structural elements (headers, bullets, bold) even in plain-prose contexts. When explicitly instructed to avoid markdown, "overt features like headers and bullets are eliminated or nearly eliminated" in most models tested, showing the behaviour is a suppressible training artifact from formatting-heavy training data.
**Source**: [arXiv:2603.27006 — The Last Fingerprint: How Markdown Training Shapes LLM Prose](https://arxiv.org/pdf/2603.27006) (academic, 12 models across 5 providers tested); [Purple Frog Systems — 11 Ways to Spot AI-Generated Text](https://www.purplefrogsystems.com/2025/01/11-ways-to-spot-ai-generated-text/); [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Bold-First Bullets"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1) (both practitioner, corroborating)
**Confidence**: High for the general markdown-leakage mechanism (peer-reviewed-equivalent academic testing across providers); Medium for the specific "bold-first-bullet" formatting convention (1 academic source on markdown leakage generally + 2 corroborating practitioner observations of this specific pattern)

### 6. False Balance / Unresolved "On the Other Hand" Padding

**Example**: A request for a recommendation answered with several paragraphs of pros/cons for every option, no stated preference, closing with "ultimately, it depends on your specific needs and priorities."
**Likely Mechanism**: Consistent with RLHF-driven sycophancy/hedging (same root mechanism as Finding 9 (RLHF sycophancy/hedging) in the linked doc: reward models favour agreeable, non-committal responses that are less likely to contradict any reader). No dedicated academic study of "false balance" as a named phenomenon in AI text specifically was found; the closest sourcing is general hedging-language research plus practitioner observation.
**Source**: [(PDF) Hedges and Boosters in AI and Human Writing: A Comparative Analysis](https://www.researchgate.net/publication/384065620_HEDGES_AND_BOOSTERS_IN_AI_AND_HUMAN_WRITING_A_COMPARATIVE_ANALYSIS) — academic, [Restricted Access] (403 on fetch; title/authors logged for follow-up per operational-safety degraded-mode protocol); [Northeastern University — What Are the Real Signs of AI Writing?](https://news.northeastern.edu/2026/09/17/signs-of-ai-writing/) (_.edu, citing named linguists Terra Blevins, Sofia Teixeira, Heather Littlefield)
**Confidence**: Medium (1 restricted-access academic source on the underlying hedging mechanism + 1 accessible `_.edu` source corroborating the general hedging/agreeableness pattern; the specific "false balance" framing itself remains practitioner-level, per Knowledge Gap 2)

### 7. Hedge Stacking (Compounding Qualifiers on One Claim)

**Example**: "While there are certainly valid concerns, it is generally worth considering that, in most cases, this approach could potentially work."
**Likely Mechanism**: Distinct from single-hedge use (which is a normal, legitimate register): stacking is documented as a distinguishing AI tell because trained writers build caution into sentence architecture once, while generated text stacks multiple short hedge devices onto the same claim rather than integrating uncertainty structurally. This is a specific case of the same RLHF-agreeableness mechanism as Finding 9 (RLHF sycophancy/hedging): each hedge independently reduces the chance of a "wrong" confident assertion.
**Source**: [Blake Stockton — "the most prominent AI writing tell"](https://www.blakestockton.com/p/red-flag-phrases); [mirrbyjack Substack — 13 Signs That Expose AI-Written Text](https://mirrbyjack.substack.com/p/13-signs-that-expose-ai-written-text); [Leap AI — Hedging Words in AI Text](https://www.tryleap.ai/learn/hedging-words-in-ai-text) (commercial AI-tooling vendor — bias flag); [(PDF) Hedges and Boosters in AI and Human Writing](https://www.researchgate.net/publication/384065620_HEDGES_AND_BOOSTERS_IN_AI_AND_HUMAN_WRITING_A_COMPARATIVE_ANALYSIS) (academic, [Restricted Access])
**Confidence**: Medium (3 converging practitioner sources, one with a commercial bias flag, plus one restricted-access academic source specifically studying hedges/boosters in AI vs. human writing, meeting the medium-trust 3-source cross-reference rule)

### 8. Sycophantic Openers / "Praise-Prompt Envelope"

**Example**: "Certainly!", "Absolutely!", "Great question!", "What a fantastic idea!" as a reflexive first line before any substantive content.
**Likely Mechanism**: Directly tied to the RLHF-sycophancy mechanism in Finding 9 (RLHF sycophancy/hedging) of the linked research doc: reward models trained on human preference data reward validating, agreeable openers because human raters respond positively to affirmation regardless of accuracy. An academic interface-criticism paper names this specifically the "praise/prompt envelope": "a carefully crafted package of validation and query designed to sustain user interaction."
**Source**: [ACM — "Reading the Praise/Prompt Machine: An Interface Criticism Approach to ChatGPT," Proceedings of the 6th Decennial Aarhus Conference](https://dl.acm.org/doi/10.1145/3744169.3744194) (academic, peer-reviewed conference proceedings; [Restricted Access] — 403 on fetch, title/venue/DOI logged); [Nielsen Norman Group — Sycophancy in Generative-AI Chatbots](https://www.nngroup.com/articles/sycophancy-generative-ai-chatbots/) (extended industry/official tier); [Science — Sycophantic AI decreases prosocial intentions and promotes dependence](https://www.science.org/doi/10.1126/science.aec8352) (peer-reviewed, high-tier academic)
**Confidence**: High (2 accessible peer-reviewed/high-tier academic sources on the sycophancy mechanism generally + 1 restricted-access peer-reviewed paper naming the specific opener pattern; mechanism inherits Finding 9's (RLHF sycophancy/hedging) High rating, specific-phrase-level claim is Medium-High since the exact phrase list is corroborated only by inaccessible/practitioner sources)

### 9. Boilerplate AI Self-Disclaimers

**Example**: "As an AI language model, I don't have personal opinions or feelings, but..."; "I am not able to provide professional advice, but here is some general information..."
**Likely Mechanism**: Product of safety/RLHF training explicitly instructing self-identification and limitation-disclosure; documented critique is that the disclaimer fires reflexively even when context makes it redundant (e.g., mid-fiction, mid-roleplay), interrupting tone rather than adding information.
**Source**: [Medium — "The Disclaimers Are the Disruption"](https://medium.com/@ai_protagonist/the-disclaimers-are-the-disruption-let-chatgpt-speak-without-breaking-the-moment-38707ed3e6e5); [Bellingham Technical College LibGuides — AI Disclaimers](https://btc.ctc.libguides.com/c.php?g=1438717&p=10733570) (educational-institution library guide, extended official/academic-adjacent tier)
**Confidence**: Low-Medium (2 sources, one medium-trust practitioner and one institutional library guide describing rather than analyzing the pattern; no academic study quantifying disclaimer frequency was found, per Knowledge Gap 3)

### 10. Stock Closers ("I hope this helps!", "Let me know if you have any other questions", "Feel free to reach out")

**Example**: A factual answer ending with "I hope this clarifies things! Let me know if you have any other questions or need further assistance."
**Likely Mechanism**: Same engagement-sustaining mechanism as Entry 8's "praise/prompt envelope" (ACM paper) applied to the closing rather than opening position: a reflexive invitation to continue the interaction, consistent with RLHF optimising for continued engagement/satisfaction ratings rather than terse task completion.
**Source**: [Turn Off Communications — ChatGPT's Language Tics Field Guide](https://www.turn-off-communications.com/blog/chatgpts-language-tics-a-field-guide-2025); [DeGPT — The Ultimate ChatGPT Tells List](https://www.degpt.app/blog/chatgpt-tells-phrases-list) (commercial AI-detection vendor — bias flag); [Sapling.ai — ChatGPT's Favorite Phrases](https://sapling.ai/devblog/chatgpt-phrases/) (commercial grammar/writing-tool vendor — bias flag)
**Confidence**: Low-Medium (3 practitioner sources converge, but two of three carry a commercial-interest bias flag per bias-detection checklist; no academic source located, per Knowledge Gap 3)

### 11. Summary-Restates-the-Question Padding ("Fractal Summaries")

**Example**: "You asked about X. To answer your question about X: [answer]. In summary, regarding X, [restatement of the same answer]."
**Likely Mechanism**: Practitioner-observed pattern of restating the prompt before answering, then re-summarising the answer at the end: a "tell me what you'll tell me, tell me, tell me what you told me" structure repeated at every document level, where inverted-pyramid structure (Finding 2, lead-with-the-answer) would prescribe using it once at the top level. Likely a spillover of instruction-following training that over-generalises "restate to confirm understanding."
**Source**: [Artificial Corner — How to Get 10x Better AI Answers](https://artificialcorner.com/p/better-ai-answers); [gist.github.com/ossa-ma — "Fractal Summaries," "One-Point Dilution"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (2 practitioner sources, neither academic nor high-tier; distinguishable from legitimate inverted-pyramid summarization by redundancy rather than structure, per Knowledge Gap 3)

### 12. Semicolon/Colon-as-Crutch

**Example**: "The results were clear: engagement increased; retention improved; costs decreased." (used reflexively across many consecutive sentences/paragraphs rather than for two genuinely balanced clauses)
**Likely Mechanism**: Documented as the em-dash's punctuation siblings, sharing the RLHF/training-frequency amplification mechanism argued for em-dashes in Finding 6 (em-dash overuse) of the linked doc, applied here to colon/semicolon. Practitioner consensus locates the problem in repetition density and proximity, using the same "legitimate mark, illegitimate overuse" framing Finding 6 (em-dash overuse) applies in that doc's Conflict 1.
**Source**: [Blake Stockton — "Colons, Colons Everywhere"](https://www.blakestockton.com/colons-everywhere/); [Sam Woolfe — Has AI Spoiled the Use of the Em Dash and Semicolon?](https://www.samwoolfe.com/2026/03/ai-use-of-em-dash-semicolon.html); [tlinsights Substack — Surplus Semicolon Syndrome](https://tlinsights.substack.com/p/surplus-semicolon-syndrome) (3 independent medium-trust sources, cross-referenced per medium-trust tier rule)
**Confidence**: Medium (3-source practitioner convergence per medium-trust cross-reference rule; no academic frequency study specific to colon/semicolon was found, unlike em-dash's arXiv:2503.17965, per Knowledge Gap 4)

### 13. "Not X. Not Y. Just Z." Dramatic Countdown Construction

**Example**: "Not a bug. Not a feature. A fundamental design flaw."
**Likely Mechanism**: A structural sibling of the "it's not just X, it's Y" antithesis already documented in Finding 7 (antithesis construction) of the linked doc, but built as a three-beat negation-countdown rather than a two-part contrast. No separate causal study exists for this triadic variant; treat it as the same pattern-completion/RLHF-articulateness mechanism generalised to a triadic form. It also connects to the "rule-of-three" tendency in the AI-slop taxonomy, Finding 8 (AI-slop taxonomy).
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, logged per this catalogue's mandate to record gaps rather than omit them; see Knowledge Gap 5)

### 14. False Ranges ("From X to Y" Non-Spectrum)

**Example**: "From innovation to implementation to cultural transformation": items strung together with "from...to..." that do not actually sit on a meaningful continuum.
**Likely Mechanism**: Hypothesized as pattern-completion of a familiar rhetorical frame ("from A to B") applied for cadence/grandiosity rather than genuine range; no formal study located.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "False Ranges"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, per Knowledge Gap 5)

### 15. Anaphora Abuse (Repeated Sentence Openings)

**Example**: "They assume that users will pay. They assume that developers will build. They assume that markets will follow." This repeats an identical opening clause across consecutive sentences for rhetorical effect, in contexts (non-persuasive prose) where the device is unearned.
**Likely Mechanism**: Overlaps with the sentence-length/structure monotony named in the AI-slop taxonomy (Finding 8 of the linked doc) but is a distinct device (repeated opening words vs. uniform length); likely the same pattern-completion tendency toward "sounding rhetorical" documented generally for RLHF-favored articulateness.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Anaphora Abuse"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, per Knowledge Gap 5)

### 16. Superficial "-ing" Participle Phrases (Tacked-On Significance)

**Example**: "The festival features local vendors, contributing to the region's rich cultural heritage." A dangling participial clause, added to inflate perceived significance without adding information.
**Likely Mechanism**: Practitioner-hypothesized filler mechanism, similar in effect to the "surface-coherence-masking-low-information-density" filler already named in the AI-slop taxonomy (Finding 8) but identifies the specific grammatical vehicle (participle phrase) rather than the general phenomenon.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Superficial '-ing' Phrases"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, per Knowledge Gap 5)

### 17. Vague Unnamed Attribution

**Example**: "Industry experts agree that..."; "Studies have shown that..." with no citation, study name, or named expert.
**Likely Mechanism**: Consistent with hedging/confidence-inflation training dynamics: attributing a claim to an unspecified authority lets the model sound evidence-based without committing to a checkable source, plausibly because training data contains this construction frequently in low-rigor web content the model was trained on. No dedicated causal study located.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Vague Attributions"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1); corroborated generally (not phrase-specifically) by [SlopDetector — The AI Words List](https://slopdetector.org/blog/ai-words-list) noting "'studies have shown' with no citation" as a named phrase-level tell (commercial vendor — bias flag)
**Confidence**: Low-Medium (2 sources, one single-author practitioner list and one commercial-vendor list with a bias flag; no academic source located, per Knowledge Gap 3)

### 18. Complexity Inflation Without Clarity Gain

**Example**: AI-generated text scoring a Flesch-Kincaid grade level of ~16.6 and a Gunning-Fog index of ~20.1, versus human (L2 student) text at ~12.1 and ~14.2 respectively on the same task, despite the human text being independently rated higher on "readability and communicative success."
**Likely Mechanism**: Peer-reviewed corpus finding: LLM output shows greater lexical diversity and syntactic complexity (Type-Token Ratio 0.69 vs. 0.61; Dependent Clauses per T-Unit 0.75 vs. 0.57) than comparable human writing, but this complexity does not translate into better communicative clarity: a measurable "sounds more sophisticated, communicates less clearly" trade-off. The paper reports this as a corpus-comparison finding without attributing a specific causal training mechanism.
**Source**: [Frontiers in Education — Lexical diversity, syntactic complexity, and readability: a corpus-based analysis of ChatGPT and L2 student essays](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2025.1616935/full) (peer-reviewed academic journal; frontiersin.org treated as within the academic-tier spirit per the domain-extension precedent established in the linked prior research, alongside science.org/nngroup.com/gov.uk)
**Confidence**: Medium (single peer-reviewed academic source, but "authoritative sufficiency" applies per diminishing-returns rule 3: a peer-reviewed corpus study with reported quantitative methodology is sufficient alone. No independent replication was found in this search pass, per Knowledge Gap 6)

### 19. Dead Metaphor Overextension

**Example**: A single extended metaphor (e.g., comparing a product roadmap to a "journey") reintroduced and re-referenced at every subsequent section of a document, well past the point the metaphor adds clarity.
**Likely Mechanism**: Practitioner-hypothesized as a side effect of maintaining topical coherence across a long generation. Once a metaphor is introduced, the model appears to treat it as an established "concept" to be referenced consistently rather than retired.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Dead Metaphors"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, per Knowledge Gap 5)

### 20. Unicode/Symbol Decoration Overuse

**Example**: Overuse of arrows (→), smart quotes, bullet-substitute glyphs, or em-dash-adjacent symbols in running prose where a plain word or comma would be typed by a human writer.
**Likely Mechanism**: Same markdown/formatting-training-leakage mechanism documented for headers/bullets/em-dashes in Entry 5 and Finding 6 (em-dash overuse) of the linked doc: these are additional surviving fragments of the model's markdown/rich-text training distribution appearing in plain-text output.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Unicode Decoration"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1); mechanism corroborated by [arXiv:2603.27006 — The Last Fingerprint](https://arxiv.org/pdf/2603.27006) (academic, studies the general markdown-leakage mechanism though not this specific symbol set)
**Confidence**: Low-Medium (1 practitioner observation of the specific symbol pattern + 1 academic source corroborating the general leakage mechanism rather than the specific symbols, per Knowledge Gap 5)

### 21. Rigid Concession-Dismissal Formula ("Despite its challenges...")

**Example**: "Despite its challenges, remote work ultimately offers more benefits than drawbacks." A fixed formula that raises an objection only to wave it away, rather than genuinely weighing it.
**Likely Mechanism**: A structural variant of the false-balance pattern (Entry 6): it raises the _appearance_ of having considered a counterpoint (satisfying the sycophancy-driven urge to seem balanced/agreeable, Finding 9) while resolving it formulaically rather than substantively.
**Source**: [gist.github.com/ossa-ma — AI Writing Tropes to Avoid, "Despite Its Challenges"](https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1)
**Confidence**: Low (single practitioner source, though the underlying sycophancy mechanism it plausibly connects to is independently well-evidenced per Finding 9, see Knowledge Gap 5)

---

## Source Analysis

| Source                                                            | Domain                      | Reputation                                                               | Type                | Access Date | Cross-verified                                            |
| ----------------------------------------------------------------- | --------------------------- | ------------------------------------------------------------------------ | ------------------- | ----------- | --------------------------------------------------------- |
| Originality.AI — Obvious ChatGPT Sayings                          | originality.ai              | Medium (commercial AI-detection vendor — bias flag)                      | Practitioner        | 2026-09-25  | Y                                                         |
| Blake Stockton — Don't Write Like AI series                       | blakestockton.com           | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| Jodie Cook — Ban List                                             | jodiecook.com               | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| Metric37 — Common AI Words and Phrases                            | metric37.com                | Medium (commercial — bias flag)                                          | Practitioner        | 2026-09-25  | Y                                                         |
| SynkrLAB — Overused Words and Phrases                             | synkrlab.com                | Medium (commercial — bias flag)                                          | Practitioner        | 2026-09-25  | Y                                                         |
| Turn Off Communications — Language Tics Field Guide               | turn-off-communications.com | Medium (commercial comms consultancy — bias flag)                        | Practitioner        | 2026-09-25  | Y                                                         |
| arXiv:2412.11385 — Why Does ChatGPT "Delve" So Much?              | arxiv.org                   | High                                                                     | Academic            | 2026-09-25  | Y                                                         |
| Medium — Jake Orlowitz, overused-words piece                      | medium.com                  | Medium                                                                   | Practitioner        | 2026-09-25  | Corroborating                                             |
| SlopDetector — The AI Words List                                  | slopdetector.org            | Medium (commercial AI-detection vendor — bias flag)                      | Practitioner        | 2026-09-25  | Corroborating                                             |
| Medium — Deborah MT, Title Case                                   | medium.com                  | Medium                                                                   | Practitioner        | 2026-09-25  | N (single source)                                         |
| arXiv:2603.27006 — The Last Fingerprint (markdown training)       | arxiv.org                   | High                                                                     | Academic            | 2026-09-25  | Y                                                         |
| Purple Frog Systems — 11 Ways to Spot AI Text                     | purplefrogsystems.com       | Medium (IT consultancy — bias flag)                                      | Practitioner        | 2026-09-25  | Y                                                         |
| gist.github.com/ossa-ma — AI Writing Tropes to Avoid              | github.com (user gist)      | Medium                                                                   | Practitioner        | 2026-09-25  | Y (primary source for Entries 13-17, 19-21)               |
| ResearchGate — Hedges and Boosters in AI and Human Writing        | researchgate.net            | High (academic)                                                          | Academic            | 2026-09-25  | [Restricted Access — 403]                                 |
| Northeastern University News — Real Signs of AI Writing           | news.northeastern.edu       | High (\*.edu, extended)                                                  | Academic/journalism | 2026-09-25  | Y                                                         |
| mirrbyjack Substack — 13 Signs That Expose AI-Written Text        | mirrbyjack.substack.com     | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| Leap AI — Hedging Words in AI Text                                | tryleap.ai                  | Medium (commercial AI-tooling vendor — bias flag)                        | Practitioner        | 2026-09-25  | Y                                                         |
| ACM — Reading the Praise/Prompt Machine                           | dl.acm.org                  | High (academic, peer-reviewed)                                           | Academic            | 2026-09-25  | [Restricted Access — 403]                                 |
| Nielsen Norman Group — Sycophancy in Generative-AI Chatbots       | nngroup.com                 | High (extended industry/official per the prior research doc's precedent) | UX research         | 2026-09-25  | Y                                                         |
| Science (AAAS) — Sycophantic AI decreases prosocial intentions    | science.org                 | High (peer-reviewed)                                                     | Academic            | 2026-09-25  | Y                                                         |
| Medium — "The Disclaimers Are the Disruption"                     | medium.com                  | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| Bellingham Technical College LibGuides — AI Disclaimers           | btc.ctc.libguides.com       | Medium-High (educational institution, extended)                          | Institutional       | 2026-09-25  | Y                                                         |
| DeGPT — Ultimate ChatGPT Tells List                               | degpt.app                   | Medium (commercial AI-detection vendor — bias flag)                      | Practitioner        | 2026-09-25  | Y                                                         |
| Sapling.ai — ChatGPT's Favorite Phrases                           | sapling.ai                  | Medium (commercial grammar-tool vendor — bias flag)                      | Practitioner        | 2026-09-25  | Y                                                         |
| Artificial Corner — 10x Better AI Answers                         | artificialcorner.com        | Medium                                                                   | Practitioner        | 2026-09-25  | Corroborating                                             |
| Sam Woolfe — Has AI Spoiled the Em Dash and Semicolon?            | samwoolfe.com               | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| tlinsights Substack — Surplus Semicolon Syndrome                  | tlinsights.substack.com     | Medium                                                                   | Practitioner        | 2026-09-25  | Y                                                         |
| Frontiers in Education — corpus analysis of ChatGPT vs. L2 essays | frontiersin.org             | High (peer-reviewed, extended academic tier)                             | Academic            | 2026-09-25  | N (single source, authoritative-sufficiency rule applied) |

Reputation: High: 8 (28%) | Medium-High: 1 (3%) | Medium: 20 (69%) | Note: this catalogue leans more heavily on medium-trust/practitioner sourcing than the linked prior research document (which achieved 59% High) because the categories in scope here are explicitly the _newer, less formally studied_ tail of the AI-writing-tell literature; this is disclosed per-entry via Confidence ratings rather than smoothed over.

Domain-extension log (per the established precedent in the linked prior research document): nngroup.com and frontiersin.org treated within the "academic/official" spirit; news.northeastern.edu treated as \*.edu per the literal trusted-domain rule (no extension needed); btc.ctc.libguides.com (educational institution) extended similarly to how gov.uk content-design pages were extended previously. All other non-listed domains (medium.com-hosted authors, all `.substack.com` blogs, commercial AI-detection/writing-tool vendors, github.com-hosted personal gists) are treated as medium_trust per the config's general tier definition and were held to the 3-source cross-reference bar where used as sole support for a claim; where that bar was not met, entries are explicitly marked Low confidence rather than omitted.

## Knowledge Gaps

### Gap 1: Stock transitions/formulaic openers lack a peer-reviewed corpus study

**Issue**: Entries 1-2 (stock connectives, formulaic openers) are the most widely repeated claims across practitioner sources but no academic corpus study analogous to the "excess vocabulary" papers (Finding 7 of the linked doc) was found isolating these specific phrase classes. **Attempted**: Searched arXiv and Google Scholar-adjacent queries for corpus studies of transition-word frequency in LLM output; found only vocabulary-inflation studies for content words (delve, underscore, etc.), not function/transition phrases. **Recommendation**: Treat as Medium confidence pending a formal frequency study; the underlying next-token-safety mechanism is well-established even where the specific phrase-frequency claim is not.

### Gap 2: "False balance" has no dedicated academic name or study

**Issue**: Entry 6 describes a real, widely observed pattern, but the closest academic grounding is general hedging/sycophancy research (Finding 9) rather than a study of "false balance" specifically. **Attempted**: Searched for "false balance AI writing," "on the other hand" AI critique, and sycophancy literature for a named sub-phenomenon; found none. **Recommendation**: Treat the pattern as a plausible, not yet formally isolated, corollary of documented sycophancy research.

### Gap 3: Several entries (9, 10, 11, 17) rest on 1-2 sources with commercial-interest bias flags

**Issue**: Boilerplate disclaimers, stock closers, restate-the-question padding, and vague attribution are each corroborated by at most 2 sources, and in several cases one of those sources is a commercial AI-detection or AI-writing-tool vendor with a direct interest in promoting the "AI tells are real and detectable" narrative. **Attempted**: Searched specifically for academic or non-commercial sourcing for each; found none beyond what's cited. **Recommendation**: These entries are usable as a checklist but should be weighted lower than entries with academic backing (8, 18) or 3-source medium-trust convergence (1, 2, 7, 12) when prioritizing which tics to enforce mechanically.

### Gap 4: Colon/semicolon overuse lacks a frequency study analogous to the em-dash's arXiv:2503.17965

**Issue**: Entry 12 is well-corroborated at the practitioner level (3 independent sources) but, unlike em-dash (Finding 6 of the linked doc), no peer-reviewed frequency-multiplier study was found for colons/semicolons specifically. **Attempted**: Searched arXiv for "semicolon frequency LLM" and "colon overuse GPT corpus"; found none. **Recommendation**: Monitor for a formal punctuation-frequency study; the qualitative pattern is safe to treat as Medium confidence via convergence in the interim.

### Gap 5: Entries 13-16, 19, 20 (partial), 21 rest on a single practitioner source (one gist)

**Issue**: A single, unusually thorough practitioner document (gist.github.com/ossa-ma) is the sole source for seven catalogue entries. This is a real risk of over-relying on one author's taxonomy, even though the entries independently ring true against the general RLHF/pattern-completion mechanisms documented elsewhere in this catalogue and the linked research. **Attempted**: Searched independently for each named pattern (anaphora abuse, false ranges, dead metaphors, etc.) by description rather than by the gist's own terminology; found no independent corroboration for these specific framings within the turn budget available. **Recommendation**: Treat these seven entries as a documented but unverified-independently checklist, useful for a mechanical pattern-matching pass; flag them internally as single-source until corroborated. Do not present these seven as equivalent in evidentiary weight to the academically-backed entries (5, 8, 18) or the 3-source-converged entries (1, 2, 7, 12) if this catalogue is cited externally.

### Gap 6: Complexity-inflation finding (Entry 18) is single-sourced despite being peer-reviewed

**Issue**: The Frontiers in Education corpus study is methodologically rigorous (Coh-Metrix, Text Inspector, Lu's Syntactic Complexity Analyzer; n=50+50) but no independent replication was located in this search pass. **Attempted**: Searched for other corpus studies comparing LLM vs. human text on readability-vs-complexity trade-offs; found related but not directly comparable studies (the arXiv excess-vocabulary papers measure vocabulary, not readability-complexity trade-off directly). **Recommendation**: Applied the "authoritative sufficiency" diminishing-returns rule (a single peer-reviewed source with transparent methodology is sufficient) but flag for a second source if this finding needs to survive external scrutiny.

### Gap 7: Two academic sources are formally cited but inaccessible (403 responses)

**Issue**: The ResearchGate hedges/boosters paper (Entry 6, 7) and the ACM "Praise/Prompt Machine" paper (Entry 8) both returned HTTP 403 on WebFetch. Their content here is reconstructed from WebSearch result snippets, not direct primary-source verification. **Attempted**: Direct WebFetch to both URLs; both blocked. Searched for open-access mirrors/preprints; none found for either within budget. **Recommendation**: Per operational-safety degraded-mode protocol, both are marked [Restricted Access] with title/author/venue logged for future retrieval via an authenticated channel (e.g., institutional ACM/ResearchGate access) rather than dropped from the catalogue.

## Recommendations for Further Research

1. Commission or monitor for a formal corpus-frequency study of stock transition words and formulaic openers (Gap 1), analogous to the existing "excess vocabulary" methodology, to upgrade Entries 1-2 from Medium to High confidence.
2. Retrieve the ResearchGate hedges/boosters paper and the ACM praise/prompt-machine paper via institutional/authenticated access to verify the reconstructed claims in Entries 6-8 directly against the primary text (Gap 7).
3. Independently corroborate the seven single-sourced entries drawn from the ossa-ma gist (Entries 13-16, 19-21) against a second practitioner or academic source before treating them as equivalent in reliability to the rest of this catalogue (Gap 5).
4. If this catalogue is folded into `claude/skills/doc-style-review/SKILL.md` as a mechanical checklist, weight enforcement priority by Confidence rating: start with High/Medium-High entries (5, 8, 18, plus the cross-linked Findings 6-9, covering em-dash overuse, antithesis/vocabulary-inflation, the AI-slop taxonomy, and sycophancy, in the prior research doc) before the Low-confidence single-source entries.

## Full Citations

[1] Originality.AI. "What Are The Most Obvious ChatGPT AI Sayings?". <https://originality.ai/blog/obvious-chatgpt-sayings>. Accessed 2026-09-25.
[2] Stockton, B. "Don't Write Like AI" (Substack series). <https://www.blakestockton.com/p/red-flag-phrases> and <https://www.blakestockton.com/colons-everywhere/>. Accessed 2026-09-25.
[3] Cook, J. "How to write with ChatGPT: without it sounding like ChatGPT". <https://www.jodiecook.com/ban-list/>. Accessed 2026-09-25.
[4] Metric37. "Common AI Words and Phrases to Avoid". <https://metric37.com/blog/common-ai-words-and-phrases>. Accessed 2026-09-25.
[5] SynkrLAB. "ChatGPT's Most Overused Words and Phrases". <https://synkrlab.com/chatgpts-most-overused-words-and-phrases/>. Accessed 2026-09-25.
[6] Turn Off Communications. "ChatGPT's Language Tics: A Field Guide (2025)". <https://www.turn-off-communications.com/blog/chatgpts-language-tics-a-field-guide-2025>. Accessed 2026-09-25.
[7] Anonymous authors. "Why Does ChatGPT 'Delve' So Much? Exploring the Sources of Lexical Overrepresentation in Large Language Models". arXiv:2412.11385. 2024. <https://arxiv.org/pdf/2412.11385>. Accessed 2026-09-25.
[8] Orlowitz, J. "Delving into the load-bearing tapestry of AI's overused words". Medium. <https://medium.com/@jakeorlowitz/delving-into-the-load-bearing-tapestry-of-ais-overused-words-a2a0024cee9a>. Accessed 2026-09-25.
[9] SlopDetector. "The AI Words List: 120+ Phrases ChatGPT Overuses". <https://slopdetector.org/blog/ai-words-list>. Accessed 2026-09-25.
[10] Deborah MT. "Title Case is your accidental AI tell". Medium. <https://deborahmt.medium.com/title-case-is-your-accidental-ai-tell-2e83bbe46fe3>. Accessed 2026-09-25.
[11] Authors, various. "The Last Fingerprint: How Markdown Training Shapes LLM Prose". arXiv:2603.27006. 2026. <https://arxiv.org/pdf/2603.27006>. Accessed 2026-09-25.
[12] Purple Frog Systems. "11 Ways to Spot AI-Generated Text". <https://www.purplefrogsystems.com/2025/01/11-ways-to-spot-ai-generated-text/>. Accessed 2026-09-25.
[13] ossa-ma. "AI Writing Tropes to Avoid". GitHub Gist. <https://gist.github.com/ossa-ma/f3baa9d25154c33095e22272c631f5a1>. Accessed 2026-09-25.
[14] Authors, various. "Hedges and Boosters in AI and Human Writing: A Comparative Analysis". ResearchGate. 2024. <https://www.researchgate.net/publication/384065620_HEDGES_AND_BOOSTERS_IN_AI_AND_HUMAN_WRITING_A_COMPARATIVE_ANALYSIS>. Accessed 2026-09-25. [Restricted Access]
[15] Northeastern University. "What Are the Real Signs of AI Writing?". News @ Northeastern. 2026. <https://news.northeastern.edu/2026/09/17/signs-of-ai-writing/>. Accessed 2026-09-25.
[16] mirrbyjack (Heijnen, L.). "13 Signs That Expose AI-Written Text". Substack. <https://mirrbyjack.substack.com/p/13-signs-that-expose-ai-written-text>. Accessed 2026-09-25.
[17] Leap AI. "Hedging Words in AI Text — Why 'It's Important to Note' Flags". <https://www.tryleap.ai/learn/hedging-words-in-ai-text>. Accessed 2026-09-25.
[18] Authors, various. "Reading the Praise/Prompt Machine: An Interface Criticism Approach to ChatGPT". Proceedings of the Sixth Decennial Aarhus Conference: Computing X Crisis. ACM. 2025. <https://dl.acm.org/doi/10.1145/3744169.3744194>. Accessed 2026-09-25. [Restricted Access]
[19] Nielsen Norman Group. "Sycophancy in Generative-AI Chatbots". <https://www.nngroup.com/articles/sycophancy-generative-ai-chatbots/>. Accessed 2026-09-25.
[20] Authors, various. "Sycophantic AI decreases prosocial intentions and promotes dependence". Science (AAAS). 2026. <https://www.science.org/doi/10.1126/science.aec8352>. Accessed 2026-09-25.
[21] AI.Protagonist. "The Disclaimers Are the Disruption: Let ChatGPT Speak Without Breaking the Moment". Medium. <https://medium.com/@ai_protagonist/the-disclaimers-are-the-disruption-let-chatgpt-speak-without-breaking-the-moment-38707ed3e6e5>. Accessed 2026-09-25.
[22] Bellingham Technical College. "AI Disclaimers". LibGuides. <https://btc.ctc.libguides.com/c.php?g=1438717&p=10733570>. Accessed 2026-09-25.
[23] DeGPT. "The Ultimate ChatGPT Tells List: 50+ Phrases That Reveal AI Usage". <https://www.degpt.app/blog/chatgpt-tells-phrases-list>. Accessed 2026-09-25.
[24] Sapling.ai. "ChatGPT's Favorite Phrases". <https://sapling.ai/devblog/chatgpt-phrases/>. Accessed 2026-09-25.
[25] Artificial Corner. "How to Get 10x Better AI Answers Without Writing Better Prompts". <https://artificialcorner.com/p/better-ai-answers>. Accessed 2026-09-25.
[26] Woolfe, S. "Has AI Spoiled the Use of the Em Dash and Semicolon?". <https://www.samwoolfe.com/2026/03/ai-use-of-em-dash-semicolon.html>. Accessed 2026-09-25.
[27] tlinsights. "Surplus Semicolon Syndrome". Substack. <https://tlinsights.substack.com/p/surplus-semicolon-syndrome>. Accessed 2026-09-25.
[28] Authors, various. "Lexical diversity, syntactic complexity, and readability: a corpus-based analysis of ChatGPT and L2 student essays". Frontiers in Education. 2025. <https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2025.1616935/full>. Accessed 2026-09-25.

## Research Metadata

Duration: ~45 turns | Sources examined: 38 | Sources cited: 28 (Full Citations) | Catalogue entries: 21 | Confidence distribution: High 2, Medium-High 1, Medium 10, Low-Medium 4, Low 8 | Cross-refs: 12 of 21 entries have 2+ independent sources; 8 entries are single-sourced and explicitly flagged as Knowledge Gap 5 rather than omitted | Tool failures: 2 (ResearchGate and ACM sources returned HTTP 403; handled per operational-safety degraded-mode protocol, marked [Restricted Access] and logged for follow-up) | Output: docs/reference/ai-writing-tics-catalogue.md
