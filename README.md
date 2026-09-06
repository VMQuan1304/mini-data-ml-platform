# Mini Data & ML Platform

A deliberately small, single-cluster learning platform for two tenants: `team-data`
owns transaction ingestion and curated customer summaries; `team-ml` trains and serves
a risk model and a cited RAG API. Argo CD is the intended reconciler for workloads.

This repository is a **runnable skeleton**, not a production platform. The lightweight
validation path works without a cluster. Stateful charts and complete end-to-end wiring
are staged behind the documented profiles and should be implemented incrementally.

## Architecture

```text
transaction-producer -> Kafka -> ingestion-consumer -> MinIO raw
                                                     -> Spark -> MinIO curated
                                                               -> train.py -> MLflow
                                                                            -> model-api
docs-ingestor -> pgvector -> rag-api
Argo CD -> Kubernetes workloads; Prometheus/Grafana -> APIs, Pods and pipelines
```

See [context](docs/architecture/context.md), [containers](docs/architecture/containers.md)
and [decisions](docs/architecture/decisions.md).

## Profiles and prerequisites

- `core`: PostgreSQL, MinIO, Kafka, three data/ML apps and basic metrics; plan for 8–12 GB RAM.
- `full`: adds Airflow, Spark, MLflow, Argo CD, Prometheus and Grafana; 16 GB+ is realistic.

Required for cluster work: Docker, kubectl, kind, Helm, Terraform and Python 3.11+.
For fast offline checks only Python is required. Copy `.env.example` to an untracked
`.env` when running locally. Every committed credential is intentionally fake.

## Stable entry points

```bash
make validate        # offline syntax, contract and generator tests
make bootstrap       # check tools and create cluster
make platform-up     # install/apply shared service scaffold; PROFILE=core|full
make apps-build      # validate and build local pinned images
make deploy          # apply GitOps bootstrap manifests
make seed            # print deterministic sample events; SEED_COUNT=10
make smoke-test      # bounded Kubernetes and API checks
make platform-down   # delete only kind cluster mini-data-ml-platform
```

`bootstrap`, `platform-up`, `deploy`, and `platform-down` are idempotent. `seed` emits
the same event IDs for the same count, so consumers can exercise idempotency. The initial
`platform-up` target installs namespace/guardrail scaffolding only and prints the remaining
profile work; it does not claim that Kafka, MinIO, MLflow, Airflow or monitoring are ready.

## Expected quick validation

```text
$ make validate
python syntax: ok
json contracts: ok
golden-path generator: ok
validation: ok
```

Happy path: run `make validate`, then `SEED_COUNT=2 make seed`; two valid schema-v1 JSON
events appear. Failure/recovery: change a fixture amount to a negative number, observe the
contract test fail, restore it, and rerun `make validate`.

## Security and production boundary

Kubernetes Secrets only encode values. Production should obtain short-lived credentials
from an external secrets manager integrated with workload identity. It also needs multiple
failure domains, managed/external stateful services where appropriate, TLS, encryption at
rest, backup/restore drills, capacity tests, SLOs, audited policy enforcement, upgrade and
incident ownership. A local green demo proves none of those properties.

Start with [the platform demo runbook](docs/runbooks/platform-demo.md). Weekly decisions,
trade-offs, gaps and interview answers live under `docs/interview-notes/`.

