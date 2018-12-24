pipeline {
  environment {
    registry = 'demo345453/service'
    registryCredential = 'dockerhub'
    dockerImage = ''
  }
  agent any
  stages {
    stage('clone git') {
      steps {
        git 'https://github.com/demo345453/airport.git'
      }
    }
    stage('buil image') {
      steps{
        script {
          dockerImage = docker.build registry + ":AS-$BUILD_NUMBER"
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
       sh "docker rmi demo345453/service:AS-$BUILD_NUMBER"
     }
   }
  }
}