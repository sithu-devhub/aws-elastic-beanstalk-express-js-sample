pipeline {
    agent any   // run on the Jenkins container by default
    options {
        skipDefaultCheckout(true)   // prevent duplicate SCM checkouts
        buildDiscarder(logRotator(daysToKeepStr: '90', numToKeepStr: '100'))  // Keep logs for 90 days or 100 builds (matches your UI config)

    }
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code'
                checkout scm   // ensures repo files like package.json are available
            }
        }

        stage('Build') {
            steps {
                echo '===== [BUILD] Stage Started ====='
                echo 'Installing Node.js dependencies...'
                sh '''
                  docker run --rm \
                    -v $PWD:/app -w /app \
                    sithuj/node16-snyk:latest npm install --save
                '''
                echo 'Dependency installation finished.'
                echo '===== [BUILD] Stage Completed ====='
            }
        }

        stage('Test') {
            steps {
                echo '===== [TEST] Stage Started ====='
                echo 'Running unit tests...'
                sh '''
                  docker run --rm \
                    -v $PWD:/app -w /app \
                    sithuj/node16-snyk:latest npm test || { echo "Tests failed, check output above"; exit 1; }
                '''
                echo '===== [TEST] Stage Completed ====='
            }
        }

        stage('Security Scan') {
            steps {
                echo '===== [SECURITY SCAN] Stage Started ====='
                echo 'Authenticating with Snyk and scanning dependencies...'
                withCredentials([string(credentialsId: 'SNYK_TOKEN', variable: 'SNYK_TOKEN')]) {
                    sh '''
                    docker run --rm \
                        -e SNYK_TOKEN=$SNYK_TOKEN \
                        -v $PWD:/app -w /app \
                        sithuj/node16-snyk:latest snyk test --severity-threshold=high
                    '''
                }
                echo '===== [SECURITY SCAN] Stage Completed ====='
            }
        }


        stage('Build Docker Image') {
            steps {
                echo '===== [DOCKER IMAGE BUILD] Stage Started ====='
                echo "Building Docker image: sithu/assignment2_22466972:${BUILD_NUMBER}"
                sh 'docker build -t sithu/assignment2_22466972:${BUILD_NUMBER} .'
                echo 'Docker image build finished successfully.'
                echo '===== [DOCKER IMAGE BUILD] Stage Completed ====='
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
            // Archive logs and reports
            archiveArtifacts artifacts: '**/npm-debug.log', fingerprint: true
            archiveArtifacts artifacts: 'snyk.log', fingerprint: true
        }
    }
}