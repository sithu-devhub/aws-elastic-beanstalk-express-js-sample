pipeline {
    agent {
        docker {
            image 'node:16'
        }
    }
    options {
        // Keep logs for 90 days or 100 builds (matches your UI config)
        buildDiscarder(logRotator(daysToKeepStr: '90', numToKeepStr: '100'))
    }
    stages {
        stage('Build') {
            steps {
                echo '===== [BUILD] Stage Started ====='
                echo 'Installing Node.js dependencies...'
                sh 'npm install --save'
                echo 'Dependency installation finished.'
                echo '===== [BUILD] Stage Completed ====='
            }
        }
        stage('Test') {
            steps {
                echo '===== [TEST] Stage Started ====='
                echo 'Running unit tests...'
                sh 'npm test || { echo "Tests failed, check output above"; exit 1; }'
                echo '===== [TEST] Stage Completed ====='
            }
        }
        stage('Security Scan') {
            steps {
                echo '===== [SECURITY SCAN] Stage Started ====='
                echo 'Authenticating with Snyk and scanning dependencies...'
                withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                    sh '''
                    npm install -g snyk
                    snyk auth $SNYK_TOKEN
                    snyk test --severity-threshold=high | tee snyk.log
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
