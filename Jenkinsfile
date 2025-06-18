pipeline {
    agent any
    
    environment {
        // Azure credentials (will be set up in Jenkins)
        ARM_CLIENT_ID = credentials('azure-client-id')
        ARM_CLIENT_SECRET = credentials('azure-client-secret')
        ARM_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        ARM_TENANT_ID = credentials('azure-tenant-id')
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo 'Checking out code from repository...'
                checkout scm
            }
        }
        
        stage('Terraform Init') {
            steps {
                echo 'Initializing Terraform...'
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                echo 'Planning Terraform changes...'
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                echo 'Creating Azure resources...'
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
        stage('Get VM IP Address') {
            steps {
                echo 'Getting the VM IP address...'
                script {
                    dir('terraform') {
                        env.VM_IP = sh(
                            script: 'terraform output -raw public_ip_address',
                            returnStdout: true
                        ).trim()
                    }
                    echo "VM IP Address: ${env.VM_IP}"
                }
            }
        }
        
        stage('Wait for VM to be Ready') {
            steps {
                echo 'Waiting for VM to be accessible...'
                script {
                    sh """
                        for i in {1..30}; do
                            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 azureuser@${env.VM_IP} 'echo "VM is ready"'; then
                                echo "VM is ready!"
                                break
                            else
                                echo "Attempt \$i: VM not ready yet, waiting 10 seconds..."
                                sleep 10
                            fi
                        done
                    """
                }
            }
        }
        
        stage('Update Ansible Inventory') {
            steps {
                echo 'Updating Ansible inventory with VM IP...'
                script {
                    writeFile file: 'ansible/inventory.ini', text: """
[webservers]
${env.VM_IP} ansible_user=azureuser ansible_ssh_private_key_file=~/.ssh/id_rsa
"""
                }
            }
        }
        
        stage('Run Ansible Playbook') {
            steps {
                echo 'Configuring web server and deploying application...'
                dir('ansible') {
                    sh 'ansible-playbook -i inventory.ini install_web.yml'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo 'Testing the deployed website...'
                script {
                    sh """
                        sleep 10
                        curl -f http://${env.VM_IP} || exit 1
                        echo "Website is accessible at: http://${env.VM_IP}"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '🎉 Pipeline completed successfully!'
            echo "Your website is live at: http://${env.VM_IP}"
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
        always {
            echo 'Cleaning up...'
            // Optionally destroy resources after testing
            // dir('terraform') {
            //     sh 'terraform destroy -auto-approve'
            // }
        }
    }
}