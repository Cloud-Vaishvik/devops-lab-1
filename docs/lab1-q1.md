# Q1 — Version control with Git and GitHub (5 marks)

## 1. Toolchain installed

Ubuntu 24.04 LTS. Full runnable version in `scripts/install-tools.sh`.

```bash
sudo apt update
sudo apt install -y git
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt install -y nodejs
# gh and VS Code come from their own apt repos - see scripts/install-tools.sh
```

| Tool | Why this version | Recorded version |
|---|---|---|
| Git | apt default on 24.04 | `TODO: paste git --version` |
| GitHub CLI | creates the remote without leaving the terminal | `TODO: paste gh --version` |
| VS Code | editor required by the lab sheet | `TODO: paste code --version` |
| Node.js | **≥ 20.11** — the JUnit test reporter used in Q2 does not exist below it | `TODO: paste node --version` |

> Ubuntu 24.04's default `nodejs` package is too old for `node --test
> --test-reporter=junit`. NodeSource 20.x is installed instead. If the Test
> stage reports an unknown reporter, this is the cause.

## 2. Identity and defaults

```bash
git config --global user.name  "Rudraraj Radhwani"
git config --global user.email "rudraraj.radhwani@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --list --show-origin
```

`pull.rebase true` keeps history linear, so `git log --graph` reads as a
sequence of changes rather than a wall of merge bubbles.

**TODO — screenshot:** `git config --list --show-origin` output.

## 3. Repository structure

```
Lab 1/
├── Jenkinsfile              # the pipeline definition — Q2
├── app/                     # sample application under CI
│   ├── src/server.js        # Express: /, /healthz, /readyz
│   ├── test/server.test.js  # 5 HTTP contract tests
│   └── package.json         # lint / test / test:ci scripts
├── scripts/
│   ├── install-tools.sh     # one-shot Ubuntu 24.04 toolchain install
│   ├── lab1-commands.sh     # every command used, in order
│   └── deploy.sh            # the pipeline's deploy step
├── docs/                    # these answers
└── evidence/                # screenshots and captured output
```

## 4. Commit strategy

The lab asks for a *clean commit history*, so the work is split by concern —
one commit per logical change, each with a message saying what changed and why:

```bash
git add app/ .gitignore
git commit -m "Add sample Express app with health and readiness endpoints"
git add app/test/
git commit -m "Add HTTP contract tests so the CI test stage can fail"
git add Jenkinsfile scripts/
git commit -m "Add Jenkins CI/CD pipeline and deploy script"
git add docs/ README.md
git commit -m "Document Q1 version control and Q2 pipeline setup"
```

A single "final submission" commit would satisfy the letter of the requirement
and none of its point: the history is meant to show how the work was built.

**TODO — screenshot:** `git log --oneline --graph --decorate`.

## 5. Branching and merging

Feature work happens on a branch and merges back with `--no-ff`, so the branch
remains visible in the history instead of being flattened away:

```bash
git checkout -b feature/smoke-test
git commit -am "Verify deployed version in the smoke-test stage"
git checkout main
git merge --no-ff feature/smoke-test -m "Merge feature/smoke-test"
git branch -d feature/smoke-test
```

**TODO — screenshot:** `git log --oneline --graph --all` showing the merge.

## 6. Publishing to GitHub

```bash
gh auth login
git remote add origin https://github.com/Rudraraj24/devops-lab-1.git
git branch -M main
git push -u origin main
```

Repository: <https://github.com/Rudraraj24/devops-lab-1>

**TODO — screenshot:** the GitHub repo page showing the commit list.

## 7. Inspecting and undoing changes

| Command | What it does | When you reach for it |
|---|---|---|
| `git diff` | unstaged edits | before staging |
| `git diff --staged` | what the next commit will contain | before committing |
| `git show HEAD` | what the last commit changed | reviewing your own work |
| `git restore <f>` | discard an unstaged edit | abandon a local experiment |
| `git restore --staged <f>` | unstage, keep the edit | staged the wrong file |
| `git revert <sha>` | undo with a *new* commit | the bad commit is already pushed |

`git revert` rather than `git reset` for anything already pushed: reset rewrites
history that others may have pulled, revert does not.

## 8. `.gitignore`

```
node_modules/     # reinstallable from package-lock.json
dist/             # build output, produced by the Package stage
reports/          # test output, produced by the Test stage
staging/          # deploy target, recreated on every build
```

Everything ignored is *reproducible* — the pipeline regenerates it from
`package-lock.json` and the source. `package-lock.json` itself **is** committed,
because `npm ci` needs it to install identical dependency versions on every run.
That is what makes the pipeline reproducible rather than merely repeatable.
