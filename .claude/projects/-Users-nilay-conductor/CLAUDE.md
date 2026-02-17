# ph-conductor/conductor

## Workflow
Always use the staff-swe skill. Use TDD for all application code.
Run `nx affected` to scope test/lint/build to changed code.

## Codebase Map

### Monorepo Stack
- **Orchestrator:** Nx 22.5 (Python + TypeScript)
- **Python:** uv, FastAPI, Temporal workers, pytest, mypy, ruff
- **TypeScript:** pnpm, React 19, TanStack Router/Query, Rsbuild + Module Federation
- **CI:** GitHub Actions + Graphite CI optimizer → ArgoCD/K8s deploy

### Apps (`apps/`)

| App | Type | Stack | Notes |
|-----|------|-------|-------|
| `tenant-cmi/ui` | Frontend | React/Rsbuild MFE | CMI tenant UI, Module Federation remote |
| `tenant-cmi/api` | Backend | FastAPI | CMI API |
| `tenant-cmi/automations` | Workers | Temporal + Playwright, PDF, Twilio | RPA, doc processing, SMS/OTP |
| `tenant-poc/ui` | Frontend | React/Rsbuild MFE | POC tenant UI |
| `tenant-poc/api` | Backend | FastAPI | POC API |
| `tenant-poc/automations` | Workers | Temporal + LiveKit | Voice agents |
| `tenant-mackenzie-health/automations` | Workers | Temporal | Billing reminders |
| `shell/ui` | Frontend | React/Rsbuild | MFE host (port 2000), loads tenant remotes |
| `login/ui` | Frontend | React | Auth UI |
| `codec-server` | Backend | FastAPI | Temporal codec/KMS encryption |
| `infra/automations` | Workers | Temporal | Infrastructure automation |

### Libs (`libs/`)

| Lib | Purpose |
|-----|---------|
| `conductor/shared` | Python base: Temporal, AWS, common utils |
| `conductor/shared-temporal-codec` | Codec Server integration |
| `conductor/shared-cmi` | CMI-specific shared code |
| `concert-master/ui` | Reusable React components |
| `concert-master/auth` | Auth library |
| `concert-master/jest-config` | Shared Jest config |
| `concert-master/typescript-config` | Shared TS config |

### Deploy & Infra
- `deploy/` — Helm charts (argocd/), deployment configs
- `infrastructure/` — Terraform (AWS networking, RDS, containers, Temporal)

### Nx Tags (for selective builds)
- `tag:scope:tenant-cmi`, `tag:scope:tenant-poc`, `tag:scope:tenant-mackenzie-health`
- `tag:lang:python`, `tag:lang:typescript`
- `tag:platform:backend`, `tag:platform:frontend`, `tag:platform:automation`

## Conventions
- **Multi-tenant:** Each tenant gets isolated `apps/tenant-*/` with UI + API + automations
- **Module Federation:** Shell hosts tenant UIs as remotes, loaded dynamically
- **Temporal:** All async work goes through Temporal workflows (codec-encrypted)
- **Testing:** pytest (unit, integration, e2e markers), Jest (frontend)
- **Linting:** ruff (Python), Biome (TypeScript)
- **Secrets:** AWS Secrets Manager + ESO. Never hardcode.
