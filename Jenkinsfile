pipeline {
    agent {
        docker {
            image 'hsndocker/cluster-control:latest'
            args '-u root:root -v /home/hossein/.kube:/root/.kubecopy:ro -v /home/hossein/.minikube:/root/.minikube:ro'
        }
    }
    parameters {
        string(name: 'BACKEND_VERSION', defaultValue: 'latest')
        string(name: 'FRONTEND_VERSION', defaultValue: 'latest')
    }
    environment {
        DOCKERHUB_CRED = credentials('dockerhub-repo')
        BACKEND_VERSION = "${params.BACKEND_VERSION}"
        FRONTEND_VERSION = "${params.FRONTEND_VERSION}"
        BUILD_ID = "${env.BUILD_ID}"
    }
    stages {
        stage('Configure kubectl and terraform') {
            
            steps {
                sh 'cd /root && cp -r .kubecopy .kube'
                sh 'cd /root/.kube && rm config && mv minikube.config config'
                sh 'cp /root/terraform/terraform .'
                sh 'cp /root/kubectl/kubectl .'
            }
        } 
        stage('Deploy Integration Test') {
            steps {
                sh './terraform init'
                sh('./terraform apply -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                sh "./kubectl wait --for=condition=ready --timeout=600s -n integration-test pod/integration-${env.BUILD_ID}" 
		        sh "./kubectl exec -n integration-test integration-${env.BUILD_ID} -c backend -- bash integration.sh"
                sh "./kubectl exec -n integration-test integration-${env.BUILD_ID} -c cypress -- npx cypress run --spec cypress/integration/sample_spec.js --config-file cypress.integration.json"
            }
            post {
                always {
                    sh('./terraform destroy -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                }
            }
        }
        
    }
}
