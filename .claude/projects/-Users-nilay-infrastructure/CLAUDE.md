# ph-conductor/infrastructure

## Workflow
Always use the staff-sre skill. Never invoke TDD workflows.
Read `adr/` before proposing architectural changes. Create new ADRs for architectural decisions.

## Codebase Map

### Modules (`terraform/modules/`)

| Module | Purpose | Key Vars |
|--------|---------|----------|
| `naming` | Region short codes (ca-central-1→cac1) | — |
| `vpc` | 2 public + 2 private subnets, NAT, SGs | `vpc_cidr`, `environment`, `data_classification` |
| `rds-postgresql` | Managed PostgreSQL, Secrets Manager pw | `service`, `instance_class`, `engine_version`, `multi_az` |
| `eks` | EKS 1.31, IRSA, managed node groups | `cluster_version`, `node_groups`, `addon_versions`, `kms_key_administrators` |
| `temporal-cloud` | Temporal Cloud namespace (managed svc) | `namespace_name`, `retention_days`, `accepted_client_ca` |
| `temporal-worker-controller` | TWC operator Helm deploy | `eks_cluster_id`, `controller_version` |
| `external-secrets` | ESO Helm + IRSA for Secrets Manager | `oidc_provider_arn`, `oidc_provider`, `secrets_manager_arns` |
| `argocd` | ArgoCD Helm + GitHub App repo creds | `github_app_*`, `enable_oidc`, `enable_irsa`, `ha_enabled` |
| `api-gateway` | HTTP API GW v2, VPC Link to NLB | `nlb_listener_arn`, `custom_domain`, `route53_zone_id` |
| `lambda-temporal-trigger` | Container Lambda → Temporal workflow | `image_uri`, `temporal_host`, `temporal_namespace`, `task_queue` |

### Module Dependency Chain
```
naming → vpc → eks → {argocd, external-secrets, temporal-worker-controller}
              vpc → rds-postgresql
              vpc → api-gateway (needs NLB listener ARN from K8s)
```

### Environments (`terraform/environments/`)

| Env | Region(s) | Account | Notes |
|-----|-----------|---------|-------|
| `dev` | ca-central-1 | 553015941472 | Auto-apply on PR, single-region |
| `prod` | ca-central-1 + us-east-1 | 601699042842 | Manual apply, multi-region |
| `staging` | — | — | Not implemented yet |

Each env: one `.tf` file per concern (vpc.tf, eks.tf, rds.tf, argocd.tf, etc.)

### CI/CD (`.github/workflows/`)
- `_terraform.yml` — Reusable: plan on PR, apply on merge/manual
- `terraform-dev.yml` — Dev: apply-on-pr=true (rapid iteration)
- `terraform-prod.yml` — Prod: manual dispatch only
- `terraform-validate.yml` — fmt check + validate + Trivy security scan

## Conventions
- **Naming:** `{env}-{region_short}-{purpose}` (e.g., `eks-dev-cac1`)
- **Tags:** Environment, DataClassification, CostCentre, ManagedBy on every resource
- **Secrets:** Secrets Manager + ESO sync to K8s. Never hardcode.
- **IRSA:** Preferred over passing AWS creds to pods
- **State:** S3 + DynamoDB locking per account
- **Addon versions:** Pinned (not "most_recent") to prevent drift
