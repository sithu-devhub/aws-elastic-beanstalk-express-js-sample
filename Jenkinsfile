pipeline {
    agent any // run on the Jenkins container by default
    options {
        skipDefaultCheckout(true)
        buildDiscarder(logRotator(daysToKeepStr: '90', numToKeepStr: '100'))
    }
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code'
                checkout scm    // ensures repo files like package.json are available
                sh 'mkdir -p /tmp/build-$BUILD_NUMBER && cp -r $WORKSPACE/. /tmp/build-$BUILD_NUMBER/'
                script {
                    env.BUILD_DIR = "/tmp/build-$BUILD_NUMBER"
                }
            }
        }
        stage('Build') {
            steps {
                echo '===== [BUILD] Stage Started ====='
                echo 'Installing Node.js dependencies...'
                sh '''
                docker run --rm \
                  -v "$BUILD_DIR":/app -w /app \
                  sithuj/node16-snyk:latest \
                  sh -c "npm install 2>&1 | tee /app/build.log || { echo 'Build failed'; exit 1; }"
                '''
                // Copy build log back to workspace so Jenkins can archive it
                sh "cp $BUILD_DIR/build.log $WORKSPACE/ || true"
                echo '===== [BUILD] Stage Completed ====='
            }
        }
        stage('Test') {
            steps {
                echo '===== [TEST] Stage Started ====='
                sh '''
                docker run --rm \
                  -v "$BUILD_DIR":/app -w /app \
                  sithuj/node16-snyk:latest \
                  sh -c "npm test --verbose 2>&1 | tee /app/test.log || { echo 'Tests failed'; exit 1; }"
                '''
                // Copy test log back to workspace so Jenkins can archive it
                sh "cp $BUILD_DIR/test.log $WORKSPACE/ || true"
                echo '===== [TEST] Stage Completed ====='
            }
        }
        stage('Security Scan') {
            steps {
                echo '===== [SECURITY SCAN] Stage Started ====='
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    sh '''
                    set -o pipefail
                    docker run --rm \
                    -e SNYK_TOKEN=$SNYK_TOKEN \
                    -v "$BUILD_DIR":/app -w /app \
                    sithuj/node16-snyk:latest \
                    bash -c "snyk test --severity-threshold=high 2>&1 | tee /app/snyk.log"; \
                    EXIT_CODE=${PIPESTATUS[0]}; \
                    cp /app/snyk.log $WORKSPACE/; \
                    exit $EXIT_CODE
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
                docker build -t sithuj/assignment2_22466972:${BUILD_NUMBER} "$WORKSPACE" 2>&1 | tee "$WORKSPACE/docker-build.log"
                '''
                echo '===== [DOCKER IMAGE BUILD] Stage Completed ====='
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '===== [DOCKER PUSH] Stage Started ====='
                withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    docker push sithuj/assignment2_22466972:${BUILD_NUMBER} 2>&1 | tee "$WORKSPACE/docker-push.log" || { echo "Docker image push failed"; exit 1; }
                    docker logout
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

            // Scan console logs for "warning"/"error"
            recordIssues()
        }
    }



}
