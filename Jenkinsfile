pipeline {
    agent any
    options {
        skipDefaultCheckout(true)
        buildDiscarder(logRotator(daysToKeepStr: '90', numToKeepStr: '100'))
    }

    stages {
        stage('Checkout') {
            steps {
                deleteDir()  // clean workspace to avoid stale logs
                echo 'Checking out source code'
                checkout scm
                sh 'mkdir -p /tmp/build-$BUILD_NUMBER && cp -r $WORKSPACE/. /tmp/build-$BUILD_NUMBER/'
                script { env.BUILD_DIR = "/tmp/build-$BUILD_NUMBER" }
            }
        }

        stage('Build') {
            steps {
                echo '===== [BUILD] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail

                docker run --rm -v "$BUILD_DIR":/app -w /app sithuj/node16-snyk:latest \
                  bash -c "npm install 2>&1 | tee /app/build.log; exit ${PIPESTATUS[0]}"
                rc=$?

                # Guarantee build.log exists and overwrite with unique header
                {
                  echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                  cat "$BUILD_DIR/build.log"
                } > "$WORKSPACE/build.log"

                # Debug: check file status
                echo "=== DEBUG: Checking build.log files ==="
                ls -l "$BUILD_DIR/build.log" || echo "No build.log in BUILD_DIR"
                ls -l "$WORKSPACE/build.log" || echo "No build.log in WORKSPACE"

                echo "=== DEBUG: Content of build.log (first 20 lines) ==="
                head -n 20 "$WORKSPACE/build.log" || echo "build.log is empty"

                exit $rc
                '''
                echo '===== [BUILD] Stage Completed ====='
            }
        }


        stage('Test') {
            steps {
                echo '===== [TEST] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail
                docker run --rm -v "$BUILD_DIR":/app -w /app sithuj/node16-snyk:latest \
                bash -c "npm test --verbose 2>&1 | tee /app/test.log"
                rc=$?

                # Add build header and copy log
                {
                echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                cat "$BUILD_DIR/test.log"
                } > "$WORKSPACE/test.log"

                exit $rc
                '''
                echo '===== [TEST] Stage Completed ====='
            }
        }

        stage('Security Scan') {
            steps {
                echo '===== [SECURITY SCAN] Stage Started ====='
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    sh '''#!/bin/bash
                    set -o pipefail

                    # Run Snyk and capture exit code while still teeing logs
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    snyk test --severity-threshold=high --exit-code=1 \
                    2>&1 | tee "$BUILD_DIR/snyk.log"

                    rc=${PIPESTATUS[0]}   # real snyk exit code

                    # Export JSON report (ignore its exit status so rc is preserved)
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    snyk test --severity-threshold=high --json > "$BUILD_DIR/snyk.json" || true
                    
                    # Copy artifacts to workspace with unique header/footer
                    {
                    echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                    cat "$BUILD_DIR/snyk.log"
                    echo "===== End of Snyk Scan for Build #${BUILD_NUMBER} ====="
                    } > "$WORKSPACE/snyk.log"

                    cp "$BUILD_DIR/snyk.json" "$WORKSPACE/snyk.json"

                    # Extra safeguard: fail if JSON shows high severity
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

        stage('Build Docker Image') {
            steps {
                echo '===== [DOCKER IMAGE BUILD] Stage Started ====='
                sh '''#!/bin/bash
                set -o pipefail
                docker build -t sithuj/assignment2_22466972:${BUILD_NUMBER} "$WORKSPACE" \
                2>&1 | tee "$BUILD_DIR/docker-build.log"
                rc=$?

                # Add build header and copy log
                {
                echo "===== Jenkins Build #${BUILD_NUMBER} | Date: $(date '+%Y-%m-%d %H:%M:%S') ====="
                cat "$BUILD_DIR/docker-build.log"
                } > "$WORKSPACE/docker-build.log"

                exit $rc
                '''
                echo '===== [DOCKER IMAGE BUILD] Stage Completed ====='
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '===== [DOCKER PUSH] Stage Started ====='
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds',
                                                usernameVariable: 'DOCKER_USER',
                                                passwordVariable: 'DOCKER_PASS')]) {
                    sh '''#!/bin/bash
                    set -o pipefail
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                    # Push docker image with unique build number tag
                    docker push sithuj/assignment2_22466972:${BUILD_NUMBER} \
                    2>&1 | tee "$BUILD_DIR/docker-push.log"

                    # Tag the same image as latest
                    docker tag sithuj/assignment2_22466972:${BUILD_NUMBER} \
                                sithuj/assignment2_22466972:latest

                    # Push the latest tag (will replace old latest)
                    docker push sithuj/assignment2_22466972:latest \
                    2>&1 | tee -a "$BUILD_DIR/docker-push.log"

                    rc=$?
                    docker logout

                    # Add build header and copy log
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

        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build.log', fingerprint: true
            archiveArtifacts artifacts: 'test.log', fingerprint: true
            archiveArtifacts artifacts: 'snyk.log', fingerprint: true
            archiveArtifacts artifacts: 'docker-build.log', fingerprint: true
            archiveArtifacts artifacts: 'docker-push.log', fingerprint: true
            recordIssues()
        }
    }
}
