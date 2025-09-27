pipeline {
    agent {
        docker {
            image 'node:16'
        }
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
                sh '''
                  npm install -g snyk
                  snyk test --severity-threshold=high
                '''
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
}
