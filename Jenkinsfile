// DevOps Lab 1 - Continuous Integration & automated deployment pipeline.
// Declarative pipeline. Every stage is reproducible from a clean checkout: the
// only host prerequisites are git, node >= 20.11 and curl.
pipeline {
  agent any

  options {
    timestamps()                                     // timestamped console log = evidence
    timeout(time: 15, unit: 'MINUTES')               // a hung deploy must not block the executor
    buildDiscarder(logRotator(numToKeepStr: '20'))
    disableConcurrentBuilds()                        // one staging port, so serialise builds
  }

  environment {
    APP_DIR      = 'app'
    APP_VERSION  = "1.0.${env.BUILD_NUMBER}"
    DEPLOY_PORT  = '3001'
    DEPLOY_DIR   = "${env.WORKSPACE}/staging"
    ARTIFACT     = "devops-lab1-app-1.0.${env.BUILD_NUMBER}.tar.gz"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        sh 'git --no-pager log --oneline -5'         // proves which commit is building
      }
    }

    stage('Environment') {
      steps {
        sh '''
          set -eu
          echo "node    : $(node --version)"
          echo "npm     : $(npm --version)"
          echo "git     : $(git --version)"
          echo "workspace: $WORKSPACE"
        '''
      }
    }

    stage('Install dependencies') {
      steps {
        // npm ci installs strictly from package-lock.json, so the pipeline is
        // reproducible; fall back to npm install if the lockfile is absent.
        sh '''
          set -eu
          cd "$APP_DIR"
          if [ -f package-lock.json ]; then
            npm ci --no-audit --no-fund
          else
            echo "WARNING: no package-lock.json - falling back to npm install"
            npm install --no-audit --no-fund
          fi
        '''
      }
    }

    stage('Lint') {
      steps {
        // node --check parses without executing: catches syntax errors before
        // the test stage, with no extra dev dependency to install.
        sh 'cd "$APP_DIR" && npm run lint'
      }
    }

    stage('Test') {
      steps {
        sh '''
          set -eu
          mkdir -p reports
          cd "$APP_DIR"
          npm run test:ci
        '''
      }
      post {
        always {
          junit testResults: 'reports/junit.xml', allowEmptyResults: true
        }
      }
    }

    stage('Package') {
      steps {
        sh '''
          set -eu
          mkdir -p dist
          echo "$APP_VERSION" > "$APP_DIR/VERSION"
          tar -czf "dist/$ARTIFACT" \
              -C "$APP_DIR" src package.json package-lock.json VERSION
          ls -lh "dist/$ARTIFACT"
        '''
      }
    }

    stage('Deploy to staging') {
      steps {
        sh 'bash scripts/deploy.sh "dist/$ARTIFACT" "$DEPLOY_DIR" "$DEPLOY_PORT" "$APP_VERSION"'
      }
    }

    stage('Smoke test') {
      steps {
        // The deploy is only "successful" if the deployed process actually
        // answers. A green deploy stage on its own proves nothing.
        sh '''
          set -eu
          echo "--- /healthz ---"
          curl -fsS "http://127.0.0.1:$DEPLOY_PORT/healthz"; echo
          echo "--- / ---"
          body=$(curl -fsS "http://127.0.0.1:$DEPLOY_PORT/")
          echo "$body"
          echo "$body" | grep -q "\\"version\\":\\"$APP_VERSION\\"" \\
            || { echo "FAIL: deployed version is not $APP_VERSION"; exit 1; }
          echo "OK: staging is serving $APP_VERSION"
        '''
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'dist/*.tar.gz, reports/*.xml',
                       allowEmptyArchive: true, fingerprint: true
    }
    success { echo "Build ${env.BUILD_NUMBER} OK - ${env.APP_VERSION} deployed on :${env.DEPLOY_PORT}" }
    failure { echo "Build ${env.BUILD_NUMBER} FAILED - see the stage log above" }
    cleanup {
      // Stop the staging process so the port is free for the next build.
      sh 'bash scripts/deploy.sh --stop "" "$DEPLOY_DIR" "$DEPLOY_PORT" "" || true'
    }
  }
}
