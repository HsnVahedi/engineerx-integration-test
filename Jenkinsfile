pipeline {
    agent {
        docker {
            image 'hsndocker/aws-cli:latest'
            args "-u root:root --entrypoint=''"
        }
    }
    parameters {
        string(name: 'BACKEND_VERSION', defaultValue: 'latest')
        string(name: 'FRONTEND_VERSION', defaultValue: 'latest')
        string(name: 'CLUSTER_NAME', defaultValue: 'engineerx')
        string(name: 'REGION', defaultValue: 'us-east-2')
    }
    environment {
        ACCESS_KEY_ID = credentials('aws-access-key-id')
        SECRET_KEY = credentials('aws-secret-key')
        DOCKERHUB_CRED = credentials('dockerhub-repo')
        CYPRESS_KEY = credentials('cypress-key')
        BACKEND_VERSION = "${params.BACKEND_VERSION}"
        FRONTEND_VERSION = "${params.FRONTEND_VERSION}"
        BUILD_ID = "${env.BUILD_ID}"
        REGION = "${params.REGION}"
        CLUSTER_NAME = "${params.CLUSTER_NAME}"
    }
    stages {
        stage('Providing Access Keys') {
            steps {
                sh('aws configure set aws_access_key_id $ACCESS_KEY_ID')
                sh('aws configure set aws_secret_access_key $SECRET_KEY')
                sh('aws configure set default.region $REGION')
            }
        }
        stage('Setting kubeconfig') {
            steps {
                sh('aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME')
            }
        }
        stage('Terraform Initialization') {
            steps {
                dir('basics') {
			        sh "terraform init"
                }
                dir('emptydb') {
			        sh "terraform init"
                }
                dir('pagination') {
			        sh "terraform init"
                }
            }
        }
        stage('Deploy Integration Tests') {
            parallel {
                stage("Basics") {
                    steps {
                    	dir('basics') {
                            sh('terraform apply -var test_name=basics -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                            sh "kubectl wait --for=condition=ready --timeout=2000s -n integration-test pod/integration-basics-${env.BUILD_ID}" 
			                sh('kubectl exec -n integration-test integration-basics-$BUILD_ID -c backend -- python manage.py initdb')

                            sh('kubectl exec -n integration-test integration-basics-$BUILD_ID -c cypress -- npx cypress run --record --key $CYPRESS_KEY --spec cypress/integration/basics_spec.js --config-file cypress.integration.json')
                        }	
                    }
		            post {
                        always {
			                dir('basics') {
		                        sh('terraform destroy -var test_name=basics -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
			                }
                    	}
                    }
                }
                stage("Pagination") {
                    steps {
                    	dir('pagination') {
                            sh('terraform apply -var test_name=pagination -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                            sh "kubectl wait --for=condition=ready --timeout=2000s -n integration-test pod/integration-pagination-${env.BUILD_ID}" 
			                sh('kubectl exec -n integration-test integration-pagination-$BUILD_ID -c backend -- python manage.py initdb')

                            sh('kubectl exec -n integration-test integration-pagination-$BUILD_ID -c cypress -- npx cypress run --record --key $CYPRESS_KEY --spec cypress/integration/pagination_spec.js --config-file cypress.integration.json')
                        }	
                    }
		            post {
                        always {
			                dir('pagination') {
		                        sh('terraform destroy -var test_name=pagination -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
			                }
                    	}
                    }
                }
                stage("Empy Database") {
                    steps {
                    	dir('emptydb') {
                            sh('terraform apply -var test_name=emptydb -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
                            sh "kubectl wait --for=condition=ready --timeout=2000s -n integration-test pod/integration-emptydb-${env.BUILD_ID}" 
                            sh('kubectl exec -n integration-test integration-emptydb-$BUILD_ID -c cypress -- npx cypress run --record --key $CYPRESS_KEY --spec cypress/integration/empty_db_spec.js --config-file cypress.integration.json')
                        }
                    }
                    post {
                       	always {
				            dir('emptydb') {
				                sh('terraform destroy -var test_name=emptydb -var test_number=$BUILD_ID -var backend_version=$BACKEND_VERSION -var frontend_version=$FRONTEND_VERSION -var dockerhub_username=$DOCKERHUB_CRED_USR -var dockerhub_password=$DOCKERHUB_CRED_PSW --auto-approve')
				            }
                    	}
                    }
                }
            }
        } 
    }
}
