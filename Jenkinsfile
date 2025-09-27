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
                echo 'Building the Application'
                sh 'npm install --save'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing the application.'
                sh 'npm test'
            }
        }
        stage('Security Scan') {
            steps {
                echo 'Running dependency vulnerability scan with Snyk'
                withCredentials([string(credentialsId: 'snyk-token', variable: 'SNYK_TOKEN')]) {
                    sh '''
                      npm install -g snyk
                      snyk auth $SNYK_TOKEN
                      snyk test --severity-threshold=high | tee snyk.log
                    '''
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image of the app'
                sh 'docker build -t sithu/assignment2_22466972:${BUILD_NUMBER} .'
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
