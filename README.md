# Vault Agent Injector Demo
This guide will walk you through the process of setting up and using the Vault Agent Injector to manage your Vault secrets in a Kubernetes environment. By following the steps outlined below, you'll be able to securely inject secrets at runtime using HashiCorp Vault and Kubernetes.

<p align="center">
    <img src="./img/vault-agent-injector.drawio.svg" />
</p>

# Requirements
Everything in this demo is done locally, so there are a few requirements you need to have installed on your machine:
- [Terraform](https://www.terraform.io/downloads.html)
- [Docker](https://www.docker.com/get-started)
- [Kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)

# Usage

```shell
cd tf/
terraform init
terraform apply -auto-approve
```

```shell
# view the namespaces
kubectl get namespaces

# view the pods running
kubectl get pods -n vault
kubectl get pods -n vault-agent-injector
kubectl get pods -n example

# watch the database credentials change every 30s
k logs -fn example -l=app=example -c example
```

```shell
terraform destroy -auto-approve
```
