# Evidence checklist

The lab sheet asks for commands, configuration files, pipeline stages,
screenshots and observations. Commands live in `scripts/lab1-commands.sh` and
the configuration is `Jenkinsfile`; this folder holds the captured output.

Save screenshots with these exact names so the docs can reference them.

## Q1 — Git & GitHub

| File | What to capture |
|---|---|
| `q1-01-tool-versions.png` | `git --version && gh --version && code --version && node --version` |
| `q1-02-git-config.png` | `git config --list --show-origin` |
| `q1-03-git-status.png` | `git status` on the untracked tree, before the first commit |
| `q1-04-git-log.png` | `git log --oneline --graph --decorate` |
| `q1-05-branch-merge.png` | `git log --oneline --graph --all` showing the `--no-ff` merge |
| `q1-06-github-repo.png` | The GitHub repo page with the commit list |

## Q2 — Jenkins

| File | What to capture |
|---|---|
| `q2-01-jenkins-status.png` | `systemctl status jenkins` — `active (running)` |
| `q2-02-jenkins-unlock.png` | The unlock screen |
| `q2-03-job-config.png` | Pipeline job config: SCM, repo URL, branch, script path |
| `q2-04-stage-view.png` | Stage View, all 8 stages green |
| `q2-05-console-log.png` | Console output with timestamps |
| `q2-06-test-results.png` | Test Result page — 5 tests |
| `q2-07-artifact.png` | The archived `.tar.gz` on the build page |
| `q2-08-build-failed.png` | The deliberately broken test — red build |
| `q2-09-build-fixed.png` | The same job green again after the fix |

## Text output

Console logs are more useful as text than screenshots — they are searchable and
paste cleanly into the docs:

```bash
# From the Jenkins build page: ... → Console Output → raw
curl -o evidence/q2-console-build1.txt \
  http://localhost:8080/job/devops-lab1/1/consoleText --user <user>:<api-token>
```

## Note

Capture these from the **Ubuntu 24.04 lab machine**. The scripts were validated
on the development machine, but the marked environment is Ubuntu and the tool
versions in the screenshots must match those recorded in `docs/lab1-q1.md` §1.
