pipeline {
  environment {
    registry = 'demo345453/service'
    registryCredential = 'dockerhub'
    CONFIG_FILE="country.json"
    dockerImage = ''
    NOMAD_URL="http://10.10.10.10:4646"
  }
  agent any
  stages {
    stage('clone git') {
      steps {
        git 'https://github.com/demo345453/country.git'
      }
    }
    stage('build image') {
      steps{
        script {
          dockerImage = docker.build registry + ":CS-$BUILD_NUMBER"
        }
      }

    }
    stage('push image to registry') {
     steps{
        script {
          docker.withRegistry( '', registryCredential ) {
          dockerImage.push()
        }  
      }
    }
   }
   stage('remove image from server'){
     steps{
       sh "docker rmi demo345453/service:CS-$BUILD_NUMBER"
     }
   }
  }
}