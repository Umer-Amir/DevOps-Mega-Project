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
                    // Clean up any existing keys
                    sh 'rm -f jenkins_ssh_key jenkins_ssh_key.pub'
                    
                    // Write the SSH private key with correct permissions
                    withCredentials([file(credentialsId: 'jenkins_ssh_key', variable: 'SSH_KEY_FILE')]) {
                        sh """
                            cp "\$SSH_KEY_FILE" jenkins_ssh_key
                            chmod 600 jenkins_ssh_key
                            ls -l jenkins_ssh_key
                        """
                    }
                    
                    // Write the SSH public key
                    withCredentials([file(credentialsId: 'jenkins_ssh_key_pub', variable: 'SSH_KEY_PUB_FILE')]) {
                        sh """
                            cp "\$SSH_KEY_PUB_FILE" jenkins_ssh_key.pub
                            chmod 644 jenkins_ssh_key.pub
                            ls -l jenkins_ssh_key.pub
                        """
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
                script {
                    def maxRetries = 20
                    def publicIP = ""
                    def sshReady = false
                    
                    // Wait for IP assignment
                    echo "Waiting for public IP assignment..."
                    for (int i = 0; i < maxRetries && !publicIP; i++) {
                        sleep(time: 30, unit: 'SECONDS')
                        publicIP = sh(
                            script: "cd terraform && terraform output -raw public_ip_address",
                            returnStdout: true
                        ).trim()
                        
                        if (publicIP) {
                            echo "Public IP found: ${publicIP}"
                        } else {
                            echo "Waiting for public IP assignment (attempt ${i + 1}/${maxRetries})"
                        }
                    }
                    
                    if (!publicIP) {
                        error "Failed to get public IP after ${maxRetries} attempts"
                    }

                    // Wait for SSH to be ready
                    echo "Waiting for SSH to be ready..."
                    for (int i = 0; i < maxRetries && !sshReady; i++) {
                        sleep(time: 30, unit: 'SECONDS')
                        // Ensure key permissions before each attempt
                        sh 'chmod 600 jenkins_ssh_key'
                        def sshTest = sh(
                            script: """
                                ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -i jenkins_ssh_key adminuser@${publicIP} echo 'SSH connection test'
                            """,
                            returnStatus: true
                        )
                        if (sshTest == 0) {
                            echo "SSH is ready!"
                            sshReady = true
                        } else {
                            echo "Waiting for SSH to be ready (attempt ${i + 1}/${maxRetries})"
                        }
                    }
                    
                    if (!sshReady) {
                        error "SSH did not become ready after ${maxRetries} attempts"
                    }

                    // Final wait to ensure system is fully booted
                    sleep(time: 60, unit: 'SECONDS')
                }
            }
        }
        
        stage('Run Ansible') {
            steps {
                script {
                    def publicIP = sh(
                        script: "cd terraform && terraform output -raw public_ip_address",
                        returnStdout: true
                    ).trim()
                    
                    if (!publicIP) {
                        error "Could not get VM's public IP address"
                    }
                    
                    // Create inventory file
                    writeFile file: 'inventory.ini', text: """[webserver]
${publicIP} ansible_ssh_user=adminuser ansible_ssh_private_key_file=${WORKSPACE}/jenkins_ssh_key ansible_host_key_checking=False"""
                    
                    // Show debug information
                    sh '''
                        echo "=== Debug Information ==="
                        echo "Current directory:"
                        pwd
                        echo "Inventory file contents:"
                        cat inventory.ini
                        echo "SSH key permissions:"
                        ls -l jenkins_ssh_key
                    '''
                    
                    // Run Ansible playbook
                    sh 'ansible-playbook -i inventory.ini -v ansible/install_web.yml'
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
                    
                    // Wait for web server to be ready
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Test HTTP connection
                    def httpTest = sh(
                        script: "curl -s -f http://${publicIP}",
                        returnStatus: true
                    )
                    
                    if (httpTest == 0) {
                        echo "Web server is accessible!"
                    } else {
                        error "Failed to access web server"
                    }
                }
            }
        }
    }
    
    post {
        always {
            sh 'rm -f jenkins_ssh_key jenkins_ssh_key.pub'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed! Check logs for details.'
        }
    }
}
