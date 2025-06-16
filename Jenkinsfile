pipeline {
    agent any
    
    environment {
        ARM_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        ARM_CLIENT_ID = credentials('AZURE_CLIENT_ID')
        ARM_CLIENT_SECRET = credentials('AZURE_CLIENT_SECRET')
        ARM_TENANT_ID = credentials('AZURE_TENANT_ID')
        TF_IN_AUTOMATION = 'true'
    }

    stages {
        stage('Setup SSH Key') {
            steps {
                script {
                    // Write the SSH private key
                    withCredentials([file(credentialsId: 'jenkins_ssh_key', variable: 'SSH_KEY_FILE')]) {
                        sh 'cp "$SSH_KEY_FILE" jenkins_ssh_key'
                        sh 'chmod 600 jenkins_ssh_key'
                    }
                    // Write the SSH public key
                    withCredentials([file(credentialsId: 'jenkins_ssh_key_pub', variable: 'SSH_KEY_PUB_FILE')]) {
                        sh 'cp "$SSH_KEY_PUB_FILE" jenkins_ssh_key.pub'
                    }
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -no-color'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -no-color -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -no-color -auto-approve tfplan'
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
${publicIP} ansible_user=adminuser ansible_ssh_private_key_file=jenkins_ssh_key ansible_host_key_checking=False"""
                    
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
        cleanup {
            sh 'rm -f jenkins_ssh_key jenkins_ssh_key.pub'
        }
    }
}
