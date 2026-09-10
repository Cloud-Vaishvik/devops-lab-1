# Q2 — Jenkins CI/CD pipeline (5 marks)

## 1. Installing Jenkins on Ubuntu 24.04 LTS

Jenkins needs a supported JDK; 24.04 has no Java by default.

```bash
sudo apt install -y fontconfig openjdk-21-jre
sudo wget -qO /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt update && sudo apt install -y jenkins
sudo systemctl enable --now jenkins
sudo systemctl status jenkins --no-pager
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

| Item | Value |
|---|---|
| Jenkins version | `TODO: from Manage Jenkins → System Information` |
| Java version | `TODO: paste java -version` |
| URL | http://localhost:8080 |

**TODO — screenshots:** `systemctl status jenkins` showing `active (running)`;
the unlock screen; the plugin-install screen; the finished dashboard.

### The one thing that actually breaks here

Builds run as the `jenkins` service account, not as you. If `node` is on your
PATH but not the service account's, the Install stage fails with
`node: command not found` while `node --version` works fine in your own shell:

```bash
sudo -u jenkins node --version    # must succeed before you run the job
```

Fix by installing Node system-wide (NodeSource does this), or add a NodeJS tool
under *Manage Jenkins → Tools*.

## 2. Creating the pipeline job

*New Item* → name `devops-lab1` → **Pipeline** → OK.

Under **Pipeline**:

| Field | Value |
|---|---|
| Definition | Pipeline script from SCM |
| SCM | Git |
| Repository URL | `https://github.com/Rudraraj24/devops-lab-1.git` |
| Branch | `*/main` |
| Script Path | `Jenkinsfile` |

Reading the Jenkinsfile *from SCM* rather than pasting a script into the job
box is what makes the pipeline configuration reproducible: the pipeline is
versioned with the code it builds, and a rebuild of an old commit uses that
commit's pipeline.

**TODO — screenshot:** the job configuration page.

## 3. Pipeline stages

Defined in `/Jenkinsfile`.

| # | Stage | What it does | Fails the build when |
|---|---|---|---|
| 1 | Checkout | `checkout scm`, prints last 5 commits | repo unreachable |
| 2 | Environment | records node/npm/git versions | a tool is missing |
| 3 | Install dependencies | `npm ci` from the lockfile | lockfile out of sync with package.json |
| 4 | Lint | `node --check` on every source file | syntax error |
| 5 | Test | `npm run test:ci`, writes `reports/junit.xml` | any of the 5 tests fails |
| 6 | Package | tarball `devops-lab1-app-1.0.<BUILD_NUMBER>.tar.gz` | source or lockfile missing |
| 7 | Deploy to staging | `scripts/deploy.sh` → port 3001 | app not healthy within 15 s |
| 8 | Smoke test | curls `/healthz` and `/`, asserts the version | deployed build is not the one just built |

`post` blocks: `junit` publishes the test report, `archiveArtifacts` keeps the
tarball and XML, and `cleanup` stops the staging process so the port is free for
the next build.

### Why stage 8 exists

A green Deploy stage only proves a process started. Stage 8 asserts that the
running app reports `"version":"1.0.<BUILD_NUMBER>"` — the exact build just
packaged. Without it a deploy that silently served a stale artifact would still
go green, which is the most common way a "working" pipeline lies.

### Why `npm ci` and not `npm install`

`npm ci` installs strictly from `package-lock.json` and errors if the lockfile
disagrees with `package.json`. `npm install` will happily resolve a newer
transitive dependency, so two runs of the same commit can produce different
binaries. Reproducibility is a marked requirement, so `ci` it is.

### Options set on the pipeline

| Option | Reason |
|---|---|
| `timestamps()` | timestamped console log is submittable evidence |
| `timeout(15, MINUTES)` | a hung deploy must not occupy the executor forever |
| `buildDiscarder(20)` | bounded disk use |
| `disableConcurrentBuilds()` | two builds would fight over port 3001 |

## 4. Verified locally before wiring into Jenkins

Running the stages by hand first means a red build is a real failure, not a
missing prerequisite. Package → deploy → smoke → stop was executed end to end:

```
unpacking dist/devops-lab1-app-1.0.0.tar.gz -> ./staging
installing production dependencies      added 68 packages in 5s
starting on port 3001 as version 1.0.0
healthy after 1 attempt(s) (pid 1126)
--- /healthz ---  ok
--- / ---  {"message":"DevOps Lab 1 - Foundations & Continuous Integration",
            "version":"1.0.0","build":"local","servedBy":"...","hits":1,...}
OK: version assertion passes
stopping previous instance (pid 1126) / staging stopped
curl: (7) Failed to connect to 127.0.0.1 port 3001   <- cleanup confirmed
```

Test stage, same source: **5 tests, 5 pass, 0 fail**, `reports/junit.xml`
written.

> Provenance: the run above was on the development machine
> (Node 24.16.0, Git Bash) to validate the scripts. **TODO:** re-run on the
> Ubuntu 24.04 lab machine and replace this block with that output — the marked
> environment is Ubuntu, and the versions must match section 1.

## 5. Build results

**TODO — after the first Jenkins run:**

| Build | Result | Duration | Notes |
|---|---|---|---|
| #1 | | | |

**TODO — screenshots:** Stage View with all 8 stages green; the console log;
the Test Result trend showing 5 tests; the archived artifact on the build page.

## 6. Demonstrating the pipeline actually gates

A pipeline that has only ever passed proves nothing. Break a test on a branch,
push, and screenshot the red build and its failure output — then fix it and
screenshot the green one:

```bash
git checkout -b demo/failing-test
# change an assertion in app/test/server.test.js so it fails
git commit -am "Temporarily break a test to demonstrate the CI gate"
git push -u origin demo/failing-test
```

Expected: Test stage red, Package/Deploy/Smoke never run, `junit` reports 1
failure, build marked FAILED.

**TODO — screenshots:** the failed build, then the green build after the fix.

## 7. Observations

**TODO — fill in after running.** Points worth recording:

* First build is slower than later ones — `npm ci` populates the npm cache.
* Console timestamps show where the time actually goes (usually `npm ci`).
* Did the `cleanup` block free port 3001? Check `ss -ltnp | grep 3001` after a build.
* What happened on the second build — did the old staging process interfere?
