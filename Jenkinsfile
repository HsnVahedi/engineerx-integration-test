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
        CYPRESS_KEY = credentials('cypress-key')
        BACKEND_VERSION = "${params.BACKEND_VERSION}"
        FRONTEND_VERSION = "${params.FRONTEND_VERSION}"
        BUILD_ID = "${env.BUILD_ID}"
    }
    stages {
        stage('Configure kubectl and terraform') {
            steps {

                sh 'cd /root && cp -r .kubecopy .kube'
                sh 'cd /root/.kube && rm config && mv minikube.config config'

                sh 'cp /root/terraform/terraform basics/'
                sh 'cp /root/kubectl/kubectl basics/'

		        sh 'cp /root/terraform/terraform emptydb/'
                sh 'cp /root/kubectl/kubectl emptydb/'

            }
        }
        stage('Terraform Initialization') {
            steps {
                dir('basics') {
			        sh "./terraform init"
                }
                dir('emptydb') {
			        sh "./terraform init"
                }
            }
        }
        stage('Deploy Integration Tests') {
            parallel {
                stage("Basics") {
                    steps {
                    	dir('basics') {
                            sh('./terraform apply -var test_name=basics -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                            sh "./kubectl wait --for=condition=ready --timeout=1500s -n integration-test pod/integration-basics-${env.BUILD_ID}" 
                            sh('./kubectl exec -n integration-test integration-basics-$BUILD_ID -c cypress -- npx cypress run --record --key $CYPRESS_KEY --spec cypress/integration/basics_spec.js --config-file cypress.integration.json')
                        }	
                    }
		            post {
                        always {
			                dir('basics') {
		                        sh('./terraform destroy -var test_name=basics -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
			                }
                    	}
                    }
                }
                stage("Empy Database") {
                    steps {
                    	dir('emptydb') {
                            sh('./terraform apply -var test_name=emptydb -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                            sh "./kubectl wait --for=condition=ready --timeout=1500s -n integration-test pod/integration-emptydb-${env.BUILD_ID}" 
                            sh('./kubectl exec -n integration-test integration-emptydb-$env.BUILD_ID -c cypress -- npx cypress run --record --key $CYPRESS_KEY --spec cypress/integration/empty_db_spec.js --config-file cypress.integration.json')
                        }
                    }
                    post {
                       	always {
				            dir('emptydb') {
				                sh('./terraform destroy -var test_name=basics -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
				            }
                    	}
                    }
                }
            }
        } 
    }
}
