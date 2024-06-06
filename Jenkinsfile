pipeline {
    agent any
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_1')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_KEY_1')
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'master', description: 'Git branch to build')
    }

    stages {
        stage('Checkout') {
            steps {
                catchError(buildResult: 'FAILURE', stageResult: 'SUCCESS') {
                    // Clone the Terraform repository using the specified branch
                    checkout scmGit(branches: [[name: "*/${BRANCH_NAME}"]], extensions: [], userRemoteConfigs: [[credentialsId: 'jenkins_temp', url: 'https://github.com/Roshan-Baskaran/terraform_demo_aws.git']])
                }
            }
        }

        stage('Terraform Setup') {
            steps {
                // Change to the Terraform directory
                // Initialize Terraform
                bat 'terraform init'
            }
        }

        stage('Approval') {
            steps {
                script {
                    def userInput = input(
                        id: 'UserInput', message: 'Apply or Destroy Terraform Changes?', parameters: [
                            [$class: 'ChoiceParameterDefinition', choices: 'Apply\nDestroy', description: 'Select action to perform', name: 'Action']
                        ]
                    )
                    if (userInput == 'Apply') {
                        currentBuild.description = 'Terraform Apply Approved'
                    } else if (userInput == 'Destroy') {
                        currentBuild.description = 'Terraform Destroy Approved'
                    } else {
                        error 'Action Not Recognized'
                    }
                }
            }
        }

        stage('Terraform Apply or Destroy') {
            steps {
                script {
                    if (currentBuild.description == 'Terraform Apply Approved') {
                        bat 'terraform apply -auto-approve'
                    } else if (currentBuild.description == 'Terraform Destroy Approved') {
                        bat 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }
}
