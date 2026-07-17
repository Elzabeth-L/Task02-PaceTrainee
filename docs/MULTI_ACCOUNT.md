# Multi-account model

`root.hcl` centralizes provider generation, shared S3 backend settings, native S3 locking, parameter paths, and common inputs. Three live configurations select distinct VPC CIDRs and state keys. GitHub supplies a separate account ID, region, and existing OIDC role for each target. Selecting `all` produces a three-member matrix; failures are isolated and successful accounts are not automatically reverted.

The ownership mapping is fixed even though the technical aliases remain `account-1` through `account-3`: Elizabeth's account is development, Norah's is staging, and Gokul's is production. Roll out development first, then expand only after validation.

## Planned regional rollout

| Deployment | Stage and owner | Region | Rollout status |
|---|---|---|---|
| `account-1` | Development — Elizabeth | `ap-south-1` (Mumbai) | Deploy and validate first |
| `account-2` | Staging — Norah | `ap-southeast-1` (Singapore) | Hold until development is accepted |
| `account-3` | Production — Gokul | `eu-west-1` (Ireland) | Hold until staging is accepted |

Regions are supplied as GitHub Actions variables rather than committed provider values. This keeps one module reusable while giving every account an explicit deployment location.

![Multi-account architecture](diagrams/multi-account.svg)
