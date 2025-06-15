pipeline {
    agent any

    environment {
        AZURE_SUBSCRIPTION_ID = credentials('AZURE_SUBSCRIPTION_ID')
        AZURE_CLIENT_ID       = credentials('AZURE_CLIENT_ID')
        AZURE_CLIENT_SECRET   = credentials('AZURE_CLIENT_SECRET')
        AZURE_TENANT_ID       = credentials('AZURE_TENANT_ID')
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
                    sh """
                        terraform plan -out=tfplan \
                        -var="azure_subscription_id=${AZURE_SUBSCRIPTION_ID}" \
                        -var="azure_client_id=${AZURE_CLIENT_ID}" \
                        -var="azure_client_secret=${AZURE_CLIENT_SECRET}" \
                        -var="azure_tenant_id=${AZURE_TENANT_ID}"
                    """
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
                echo "Waiting 60 seconds for VM to be ready..."
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

                    echo "Using Public IP: ${publicIP}"

                    writeFile file: 'inventory.ini', text: """[webserver]
${publicIP} ansible_user=adminuser ansible_ssh_private_key_file=~/.ssh/id_rsa"""

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

                    echo "Verifying site at http://${publicIP}"
                    sh "curl -s http://${publicIP}"
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Pipeline failed! Check logs for details.'
        }
        success {
            echo '✅ Pipeline completed successfully!'
        }
    }
}
