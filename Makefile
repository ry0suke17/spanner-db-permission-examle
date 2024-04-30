GCP_PROJECT_ID=your-gcp-project-id

GKE_CLUSTER_NAME=test-cluster
GKE_REGION=us-east1

gcp/project/check:
	 if [ `gcloud config list 2> /dev/null | grep "project = ${GCP_PROJECT_ID}" | wc -l` -eq 0 ]; then >&2 echo "ERROR: project is not ${GCP_PROJECT_ID}"; exit 1; fi

gke/context/use:
	gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${GKE_REGION}
	kubectl config use-context gke_${GCP_PROJECT_ID}_${GKE_REGION}_${GKE_CLUSTER_NAME}

gcp/terraform/plan: gcp/project/check
	terraform-v1.6.1 -chdir=./terraform/gcp plan -var="gcp_project=${GCP_PROJECT_ID}"
	
gcp/terraform/apply: gcp/project/check
	terraform-v1.6.1 -chdir=./terraform/gcp apply -var="gcp_project=${GCP_PROJECT_ID}"

gcp/terraform/destroy: gcp/project/check
	terraform-v1.6.1 -chdir=./terraform/gcp destroy -var="gcp_project=${GCP_PROJECT_ID}"

k8s/create/secret: gcp/project/check gke/context/use
	kubectl create secret generic gcp-service-account --from-file=credentials.json=credentials.json

k8s/apply: gcp/project/check gke/context/use
	kubectl apply -f ./kubernetes/manifests
