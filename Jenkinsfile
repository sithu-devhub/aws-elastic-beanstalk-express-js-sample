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
                  bash -c "npm install 2>&1 | tee /app/build.log"
                rc=${PIPESTATUS[0]}
                cp "$BUILD_DIR/build.log" "$WORKSPACE/build.log"
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
                rc=${PIPESTATUS[0]}
                cp "$BUILD_DIR/test.log" "$WORKSPACE/test.log"
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
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    bash -c "snyk test --severity-threshold=high --exit-code=1 2>&1 | tee /app/snyk.log"
                    rc=${PIPESTATUS[0]}

                    # copy the log from the build dir into Jenkins workspace
                    cp "$BUILD_DIR/snyk.log" "$WORKSPACE/snyk.log"

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
                rc=${PIPESTATUS[0]}
                cp "$BUILD_DIR/docker-build.log" "$WORKSPACE/docker-build.log"
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
                    docker push sithuj/assignment2_22466972:${BUILD_NUMBER} \
                      2>&1 | tee "$BUILD_DIR/docker-push.log"
                    rc=${PIPESTATUS[0]}
                    docker logout
                    cp "$BUILD_DIR/docker-push.log" "$WORKSPACE/docker-push.log"
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
