# Dan Fox — Preferred Stack

Default choices across projects. Project-specific deviations are noted in projects.md.
When a category has no preference listed, choose the simplest option that fits.

## Runtime & Language

- Node.js 22+ LTS (managed via mise)
- ESM modules throughout
- Type-stripped TypeScript — types for readability, stripped at runtime, not compiled
- Strict TS config where full compilation is used

## Package & Task Management

- pnpm (packages) — with per-project exceptions where a toolchain requires npm
- mise (runtime versions + task runner, replaces Makefile/npm scripts)

## Web Framework

- Fastify 5 — prefer over Express; schema validation, better performance, plugin architecture
- Zod 4 — validation at system boundaries (config, request bodies, external API responses)

## CLI Framework

- Commander — preferred for CLIs

## Testing

- Vitest — unit and integration (prefer over Jest; faster, native ESM)
- Playwright — e2e / acceptance tests
- V8 coverage provider
- Colocated test files (`*.test.ts` beside source)
- Thresholds: 85%+ lines, 75%+ branches (project-dependent; main.ts/entry points excluded)

## Frontend

- Vue (learning, preferred for new projects)
- React (comfortable, use where appropriate)
- Vanilla JS/HTML for durability-first projects — no build step, no dependency drift

## Data & Persistence (aspirational defaults)

- PostgreSQL — relational store
- Kysely — query builder (type-safe, no ORM magic)
- pg-boss — async job queue

## Observability (aspirational defaults)

- Pino — structured logging
- OpenTelemetry — tracing and metrics
- Datadog — optional managed backend

## Dependency Injection

- FP-leaning Ports and Adapters (Hexagonal arch) for simple DI
- Awilix — DI container (aspirational; not yet in production use)

## API Contracts

- Zod schemas → OpenAPI generation (aspirational)
- Spectral — OpenAPI linting

## Deployment & Infrastructure

- Netlify — static sites and simple serverless functions
- Rancher Desktop + Tilt — local Kubernetes dev
- GitHub Actions or GitLab CI
- Trunk.io — unified linter orchestration (shellcheck, prettier, markdownlint, etc.)

## Documentation & Diagrams

- Docusaurus — documentation sites
- Mermaid — general diagrams (inline in markdown)
- PlantUML + C4Model — architecture diagrams
- Decision Records — stored in `docs/decisions/`

## Security & Supply Chain

- Trunk.io (trufflehog) — secret scanning
- (p)npm audit / osv-scanner — dependency security
- CycloneDX — SBOM generation; use `@cyclonedx/cdxgen` for pnpm projects (reads lockfile natively); `@cyclonedx/cyclonedx-npm` is npm-centric and unreliable with pnpm
- SAST via GitLab CI security templates or CodeQL
