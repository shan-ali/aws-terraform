pipeline {
  agent {
    docker {
      image 'docker:20.10.12-git'
    }
  }
  stages {
    stage('Build') {
        steps {
            echo 'Building...'
            sh "docker image build -t shanali38/aws-terraform-jenkins -f docker/Dockerfile ."
        }
    }
    stage('Test') {
        steps {
            echo 'Testing..'
            sh "sleep 5"
        }
    }
    stage('Deploy') {
        steps {
            echo 'Deploying....'
            echo 'Normally, we would push the newly built image to a docker repository'
        }
    }
  }
}