pipeline {
    agent any   // top-level: use Jenkins container by default

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'sithuj/node16-snyk:latest'   // Custom Node 16 + Snyk build agent
                }
            }
            steps {
                echo 'Building the Application'
                sh 'npm install --save'
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'sithuj/node16-snyk:latest'   // Custom Node 16 + Snyk build agent
                }
            }
            steps {
                echo 'Testing the application.'
                sh 'npm test'
            }
        }

        stage('Security Scan') {
            agent {
                docker {
                    image 'sithuj/node16-snyk:latest'   // Custom Node 16 + Snyk build agent
                }
            }
            steps {
                echo 'Running dependency vulnerability scan with Snyk'
                sh 'snyk test --severity-threshold=high'
            }
        }

        stage('Build Docker Image') {
            agent any   // Jenkins container with DinD access
            steps {
                echo 'Building Docker image of the app'
                sh 'docker build -t sithu/assignment2_22466972:${BUILD_NUMBER} .'
            }
        }

        stage('Deploy') {
            agent any   // Jenkins container with DinD access
            steps {
                echo 'Deploying...'
            }
        }
    }
}
