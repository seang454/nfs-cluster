# This block tells Terraform where to store the state file.
terraform {
  # Use the local backend, meaning state is stored on this computer.
  backend "local" {
    # Path to the Terraform state file for the dev Kubespray cluster.
    path = "../../../../state/dev/asia-southeast1/kubespray-k8s.tfstate"
  }
}
