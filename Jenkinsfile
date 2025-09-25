pipeline {
    agent {
        docker {
            image 'node:16'
        }
    }
    stages {
        stage('Build') {
            steps {
                git url: '', branch: 'main'
                echo 'Building the Application'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing the application.'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
