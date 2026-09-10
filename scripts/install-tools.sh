#!/usr/bin/env bash
# Lab 1 - install and configure the toolchain on Ubuntu 24.04 LTS.
# Run once, as a user with sudo. Every command here is also listed in
# lab1-commands.sh; this file is the runnable version.
set -euo pipefail

echo "==> 0. Base system"
sudo apt update
sudo apt install -y curl wget gnupg ca-certificates apt-transport-https software-properties-common

echo "==> 1. Git"
sudo apt install -y git
git --version

echo "==> 2. GitHub CLI (used to create the remote repo without leaving the terminal)"
sudo mkdir -p -m 755 /etc/apt/keyrings
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt update && sudo apt install -y gh
gh --version

echo "==> 3. Visual Studio Code"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt update && sudo apt install -y code
code --version

echo "==> 4. Node.js 20 LTS (NodeSource - Ubuntu's default node is too old for node:test)"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version    # must be >= 20.11 for the JUnit test reporter
npm --version

echo "==> 5. Java 21 (Jenkins requires a supported JDK)"
sudo apt install -y fontconfig openjdk-21-jre
java -version

echo "==> 6. Jenkins (stable LTS channel)"
sudo wget -qO /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list >/dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable --now jenkins
sudo systemctl status jenkins --no-pager | head -5

echo
echo "==> Jenkins is on http://localhost:8080"
echo "==> Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

cat <<'NOTE'

Remaining manual steps (they need the web UI - record screenshots for evidence):
  1. Unlock Jenkins with the password above.
  2. "Install suggested plugins" (this includes Pipeline, Git and JUnit).
  3. Create the first admin user.
  4. New Item -> "devops-lab1" -> Pipeline.
  5. Pipeline -> Definition: "Pipeline script from SCM"
     SCM: Git,  Repo URL: https://github.com/Rudraraj24/devops-lab-1.git
     Branch: */main,  Script Path: Jenkinsfile
  6. Save -> Build Now.

The jenkins user runs the build, so it needs node on its PATH:
  sudo -u jenkins node --version
If that fails, add a NodeJS tool in Manage Jenkins -> Tools, or symlink node
into /usr/local/bin.
NOTE
