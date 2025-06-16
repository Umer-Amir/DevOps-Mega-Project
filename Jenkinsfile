pipeline {
    agent any
    
    environment {
        ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        ARM_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        ARM_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
        ARM_TENANT_ID = credentials('AZURE_TENANT_ID')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Wait for VM') {
            steps {
                sleep(time: 60, unit: 'SECONDS')
            }
        }
        
        stage('Run Ansible') {
            steps {
                script {
                    def publicIP = sh(
                        script: "cd terraform && terraform output -raw public_ip_address",
                        returnStdout: true
                    ).trim()
                    
                    writeFile file: 'inventory.ini', text: """[webserver]
${publicIP} ansible_user=adminuser ansible_ssh_private_key_file=${WORKSPACE}/jenkins_ssh_key"""
                    
                    sh 'ansible-playbook -i inventory.ini ansible/install_web.yml'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    def publicIP = sh(
                        script: "cd terraform && terraform output -raw public_ip_address",
                        returnStdout: true
                    ).trim()
                    
                    sh "curl -s http://${publicIP}"
                }
            }
        }
    }
    
    post {
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
    }
}
