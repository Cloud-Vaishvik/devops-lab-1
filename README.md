# DevOps Lab 1 — Foundations & Continuous Integration (ENSP461)

Git-based source control and a Jenkins CI/CD pipeline that builds, tests,
packages and deploys a sample Node.js/Express service, with a smoke test that
verifies the deployed build is the one just produced.

## Layout

| Path | Purpose |
|---|---|
| `app/` | Express app: `/` (JSON + hostname + hit counter), `/healthz`, `/readyz` |
| `app/test/` | 5 HTTP contract tests (`node:test`, no extra dev dependency) |
| `Jenkinsfile` | 8-stage declarative pipeline — **Q2** |
| `scripts/install-tools.sh` | One-shot Ubuntu 24.04 toolchain install |
| `scripts/lab1-commands.sh` | Every command used, in order |
| `scripts/deploy.sh` | The pipeline's deploy step (start / stop, idempotent) |
| `docs/lab1-q1.md` | Written answer — Git & GitHub — **Q1** |
| `docs/lab1-q2.md` | Written answer — Jenkins pipeline — **Q2** |
| `evidence/` | Screenshots and captured output |

## Quick start

```bash
# 1. Install the toolchain (Ubuntu 24.04 LTS)
bash scripts/install-tools.sh

# 2. Run the pipeline stages by hand, to prove the prerequisites are in place
cd app && npm ci && npm run lint && npm run test:ci && cd ..

# 3. Package and deploy locally
mkdir -p dist && echo "1.0.0" > app/VERSION
tar -czf dist/devops-lab1-app-1.0.0.tar.gz -C app src package.json package-lock.json VERSION
bash scripts/deploy.sh dist/devops-lab1-app-1.0.0.tar.gz ./staging 3001 1.0.0
curl -fsS http://127.0.0.1:3001/            # {"version":"1.0.0",...}
bash scripts/deploy.sh --stop "" ./staging 3001 ""

# 4. Then wire it into Jenkins — see docs/lab1-q2.md §2
```

## Pipeline stages

`Checkout → Environment → Install dependencies → Lint → Test → Package →
Deploy to staging → Smoke test`

The smoke test is the stage that matters: it asserts the running app reports
`"version":"1.0.<BUILD_NUMBER>"`. A deploy that silently served a stale artifact
would otherwise still go green.

## Design notes

**`npm ci`, not `npm install`.** `ci` installs strictly from
`package-lock.json` and fails if the lockfile and `package.json` disagree, so
two runs of the same commit install identical dependency trees. `install` may
resolve newer transitive versions, which makes a pipeline repeatable but not
reproducible.

**No Redis.** Lab 2's version of this app keeps its hit counter in Redis. Lab 1
deliberately uses an in-memory counter so the Test stage needs nothing running
besides Node — the pipeline is the subject here, not distributed state.

**`node --check` as the lint stage.** Catches syntax errors before the tests run
without adding a dev dependency that would itself need installing and pinning.

**Node ≥ 20.11 required.** `node --test --test-reporter=junit` does not exist
below that, and Ubuntu 24.04's default `nodejs` package is older — hence
NodeSource in `install-tools.sh`.

## Status

Scripts verified end to end on the development machine (Node 24.16.0):
package → deploy → smoke → stop all pass, 5/5 tests green, `reports/junit.xml`
written.

**Not yet run on the Ubuntu 24.04 lab machine or inside Jenkins.** The `TODO`
markers in `docs/lab1-q1.md` and `docs/lab1-q2.md` mark every place where real
tool versions, build results and screenshots must be pasted in. They are
placeholders on purpose — nothing in this repo claims a measurement that was
not actually taken.
