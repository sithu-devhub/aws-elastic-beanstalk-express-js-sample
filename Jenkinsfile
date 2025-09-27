pipeline {
    agent any   // run on the Jenkins container by default
    options {
        skipDefaultCheckout(true)   // prevent duplicate SCM checkouts
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
                echo 'Building the Application'
                sh '''
                  docker run --rm \
                    -v $PWD:/app -w /app \
                    sithuj/node16-snyk:latest npm install --save
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Testing the Application'
                sh '''
                  docker run --rm \
                    -v $PWD:/app -w /app \
                    sithuj/node16-snyk:latest npm test
                '''
            }
        }

        stage('Security Scan') {
            steps {
                echo 'Running dependency vulnerability scan with Snyk'
                sh '''
                  docker run --rm \
                    -v $PWD:/app -w /app \
                    sithuj/node16-snyk:latest snyk test --severity-threshold=high
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
