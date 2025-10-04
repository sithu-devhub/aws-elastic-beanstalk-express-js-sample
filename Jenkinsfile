pipeline {
    agent any
    // Runs on any available Jenkins agent.

    options {
        skipDefaultCheckout(true)   // Prevents Jenkins from checking out the repo automatically. Instead, manual checkout occurs in the "Checkout" stage.
        buildDiscarder(logRotator(daysToKeepStr: '90', numToKeepStr: '100'))    // Keeps logs/artifacts only for 90 days or 100 builds to save storage — a CI best practice.

    }

    stages {
        // ================================
        // CHECKOUT STAGE
        // ================================
        stage('Checkout') {
            steps {
                echo '===== [CHECKOUT] Stage Started ====='
                // Cleans workspace to avoid stale files or previous build leftovers.
                deleteDir()

                echo 'Checking out source code'
                // Pulls code from the source control (GitHub). 
                checkout scm

                // Copies the source to a temporary directory, isolating build context for reproducibility.
                sh 'mkdir -p /tmp/build-$BUILD_NUMBER && cp -r $WORKSPACE/. /tmp/build-$BUILD_NUMBER/'
                script { env.BUILD_DIR = "/tmp/build-$BUILD_NUMBER" }

                echo '===== [CHECKOUT] Stage Completed ====='
            }
        }

        // ================================
        // BUILD STAGE
        // ================================
        stage('Build') {
            steps {
                echo '===== [BUILD] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail

                # Build Node.js dependencies using the Docker image that includes Node + Snyk.
                docker run --rm -v "$BUILD_DIR":/app -w /app sithuj/node16-snyk:latest \
                  bash -c "npm install 2>&1 | tee /app/build.log; exit ${PIPESTATUS[0]}"
                rc=$?

                # Add metadata and copy build logs for archiving.
                {
                  echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                  cat "$BUILD_DIR/build.log"
                } > "$WORKSPACE/build.log"
                exit $rc
                '''
                echo '===== [BUILD] Stage Completed ====='
            }
        }

        // ================================
        // TEST STAGE
        // ================================
        stage('Test') {
            steps {
                echo '===== [TEST] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail
                docker run --rm -v "$BUILD_DIR":/app -w /app sithuj/node16-snyk:latest \
                bash -c "npm test --verbose 2>&1 | tee /app/test.log"
                rc=$?

                # Archive results for later review.
                {
                echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                cat "$BUILD_DIR/test.log"
                } > "$WORKSPACE/test.log"

                exit $rc
                '''
                echo '===== [TEST] Stage Completed ====='
            }
        }

        // ================================
        // SECURITY SCAN STAGE (SNYK)
        // ================================
        stage('Security Scan') {
            steps {
                echo '===== [SECURITY SCAN] Stage Started ====='
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    sh '''#!/bin/bash
                    set -o pipefail

                    # Use Snyk CLI to scan dependencies for vulnerabilities (Secure DevOps practice)
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    snyk test --severity-threshold=high --exit-code=1 \
                    2>&1 | tee "$BUILD_DIR/snyk.log"
                    rc=${PIPESTATUS[0]}

                    # Export JSON report for structured analysis.
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    snyk test --severity-threshold=high --json > "$BUILD_DIR/snyk.json" || true
                    
                    # Add header and copy artifacts for record.
                    {
                    echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                    cat "$BUILD_DIR/snyk.log"
                    echo "===== End of Snyk Scan for Build #${BUILD_NUMBER} ====="
                    } > "$WORKSPACE/snyk.log"

                    cp "$BUILD_DIR/snyk.json" "$WORKSPACE/snyk.json"

                    # Fail build if any High severity vulnerabilities are found.
                    if grep -q '"severity":"high"' "$WORKSPACE/snyk.json"; then
                    echo 'High severity vulnerabilities detected. Failing build.'
                    exit 1
                    fi

                    exit $rc
                    '''
                }
                echo '===== [SECURITY SCAN] Stage Completed ====='
            }
        }

        // ================================
        // BUILD DOCKER IMAGE STAGE
        // ================================
        stage('Build Docker Image') {
            steps {
                echo '===== [DOCKER IMAGE BUILD] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail
                docker build -t sithuj/assignment2_22466972:${BUILD_NUMBER} "$WORKSPACE" \
                2>&1 | tee "$BUILD_DIR/docker-build.log"
                rc=$?

                # Archive build logs with metadata.
                {
                echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                cat "$BUILD_DIR/docker-build.log"
                } > "$WORKSPACE/docker-build.log"

                exit $rc
                '''
                echo '===== [DOCKER IMAGE BUILD] Stage Completed ====='
            }
        }

        // ================================
        // PUSH TO DOCKER HUB STAGE
        // ================================
        stage('Push to Docker Hub') {
            steps {
                echo '===== [DOCKER PUSH] Stage Started ====='
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds',
                                                usernameVariable: 'DOCKER_USER',
                                                passwordVariable: 'DOCKER_PASS')]) {
                    sh '''#!/bin/bash
                    set -o pipefail
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    # Push image with build number tag
                    docker push sithuj/assignment2_22466972:${BUILD_NUMBER} \
                    2>&1 | tee "$BUILD_DIR/docker-push.log"

                    # Also push latest tag
                    docker tag sithuj/assignment2_22466972:${BUILD_NUMBER} \
                                sithuj/assignment2_22466972:latest
                    docker push sithuj/assignment2_22466972:latest \
                    2>&1 | tee -a "$BUILD_DIR/docker-push.log"

                    rc=$?
                    docker logout

                    # Archive logs for audit trail.
                    {
                    echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                    cat "$BUILD_DIR/docker-push.log"
                    } > "$WORKSPACE/docker-push.log"

                    exit $rc
                    '''
                }
                echo '===== [DOCKER PUSH] Stage Completed ====='
            }
        }

        // ================================
        // DEPLOYMENT STAGE (OPTIONAL)
        // ================================
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }

    // ================================
    // POST-ACTIONS (AFTER BUILD)
    // ================================
    post {
        always {
            // Archive all logs for traceability and compliance 
            archiveArtifacts artifacts: 'build.log', fingerprint: true
            archiveArtifacts artifacts: 'test.log', fingerprint: true
            archiveArtifacts artifacts: 'snyk.log', fingerprint: true
            archiveArtifacts artifacts: 'docker-build.log', fingerprint: true
            archiveArtifacts artifacts: 'docker-push.log', fingerprint: true

            //Jenkins plugin: tracks warnings or issues (e.g., from static analysis or Snyk).
            recordIssues()

        }
    }
}
