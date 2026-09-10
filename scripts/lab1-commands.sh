#!/usr/bin/env bash
# Lab 1 - every command used, in order. Run from the repo root.
# This mirrors Lab 2's lab2-commands.sh: it is the command-log deliverable,
# not a script meant to be executed end to end unattended.
set -euo pipefail

### Q1 - Version control with Git & GitHub ----------------------------------

# Install the toolchain (see scripts/install-tools.sh for the full version)
sudo apt update
sudo apt install -y git gh code nodejs
git --version && gh --version && code --version && node --version

# One-time identity + sensible defaults
git config --global user.name  "Rudraraj Radhwani"
git config --global user.email "rudraraj.radhwani@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true          # linear history, no merge-bubble noise
git config --list --show-origin               # EVIDENCE: where each setting came from

# Authenticate to GitHub over HTTPS (stores a token, no password prompts)
gh auth login
gh auth status

# Initialise the repository
mkdir -p ~/projects/DevOps/"Lab 1" && cd ~/projects/DevOps/"Lab 1"
git init
git status                                    # EVIDENCE: untracked tree before first commit

# Meaningful, staged commits - not one "final" dump
git add app/ .gitignore
git commit -m "Add sample Express app with health and readiness endpoints"
git add app/test/
git commit -m "Add HTTP contract tests so the CI test stage can fail"
git add Jenkinsfile scripts/
git commit -m "Add Jenkins CI/CD pipeline and deploy script"
git add docs/ README.md
git commit -m "Document Q1 version control and Q2 pipeline setup"
git log --oneline --graph --decorate           # EVIDENCE: clean history

# Branching: do the work on a feature branch, merge back
git checkout -b feature/smoke-test
# ...edit Jenkinsfile...
git add Jenkinsfile
git commit -m "Verify deployed version in the smoke-test stage"
git checkout main
git merge --no-ff feature/smoke-test -m "Merge feature/smoke-test"
git branch -d feature/smoke-test
git log --oneline --graph --all

# Publish to GitHub
git remote add origin https://github.com/Rudraraj24/devops-lab-1.git
git branch -M main
git push -u origin main
git remote -v

# Inspecting and undoing - the commands the lab asks you to demonstrate
git diff                    # unstaged changes
git diff --staged           # staged changes
git show HEAD               # what the last commit changed
git restore <file>          # discard an unstaged edit
git restore --staged <file> # unstage without losing the edit
git revert <sha>            # undo a pushed commit with a new commit


### Q2 - Jenkins CI/CD pipeline ---------------------------------------------

# Java 21 + Jenkins LTS (full key/repo setup in scripts/install-tools.sh)
sudo apt install -y fontconfig openjdk-21-jre
sudo apt install -y jenkins
sudo systemctl enable --now jenkins
sudo systemctl status jenkins --no-pager       # EVIDENCE: active (running)
java -version

# Unlock and configure (browser: http://localhost:8080)
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# The jenkins service account must be able to see node
sudo -u jenkins node --version
sudo -u jenkins npm --version

# Job: New Item -> devops-lab1 -> Pipeline
#      Definition: Pipeline script from SCM -> Git
#      URL: https://github.com/Rudraraj24/devops-lab-1.git
#      Branch: */main   Script Path: Jenkinsfile

# Run the pipeline locally first, so a red build is a real failure and not a
# missing prerequisite:
cd app && npm ci && npm run lint && npm run test:ci && cd ..
tar -czf dist/devops-lab1-app-1.0.0.tar.gz -C app src package.json package-lock.json VERSION
bash scripts/deploy.sh dist/devops-lab1-app-1.0.0.tar.gz ./staging 3001 1.0.0
curl -fsS http://127.0.0.1:3001/healthz ; echo
curl -fsS http://127.0.0.1:3001/ ; echo
bash scripts/deploy.sh --stop "" ./staging 3001 ""

# Trigger a build and read the results
# (Build Now in the UI, or:)
curl -X POST http://localhost:8080/job/devops-lab1/build --user <user>:<api-token>
sudo journalctl -u jenkins -n 50 --no-pager    # service-level troubleshooting

# Demonstrate that the pipeline actually gates: break a test, push, watch it fail
# then fix it and watch it go green. Screenshot BOTH builds.
