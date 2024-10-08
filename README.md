# Setup

This project includes an Ansible playbook for setting up a [Pop!_OS](https://pop.system76.com/) but could probably be adapted for any debian-based system, and most others with a few tweaks.

The playbook installs Kubernetes and deploys ArgoCD and sets up applications for Traefik, ArgoCD, and Hashicorp Vault. It also installes Docker, k9s, Signal, Stern, VSCode, the JetBrains Mono font, and sets Fish Shell as the default. It also manages a set of base packages. The main purpose of this system was for playing Steam games, but it makes a great Kubernetes development machine.

The project is released using GitHub Actions which also builds the [wsams/bitnami-kubectl](https://hub.docker.com/r/wsams/bitnami-kubectl) image.

## Install dependencies

```sh
sudo apt install ansible python3 python3-psutil
ansible-galaxy collection install kubernetes.core
export TASK_VERSION="v3.24.0"
export TASK_BIN_URL="https://github.com/go-task/task/releases/download/$TASK_VERSION/task_linux_amd64.tar.gz"
curl -L "$TASK_BIN_URL" -o /tmp/task.tar.gz
sudo tar -xf /tmp/task.tar.gz -C /usr/local/bin task && chmod +x /usr/local/bin/task
```

## Configure system using Ansible playbook

Run the playbook after installing the prerequisites.

```sh
task run_ansible
```

## Configure Kubernetes for your user

```sh
mkdir ~/.kube
sudo cp /root/.kube/config ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
```

## Use ArgoCD

ArgoCD is installed after running the Ansible playbook. You will need to initialize the admin password first.

```sh
kubectl exec -it deploy/argocd-server -n argocd -- sh -c 'argocd admin initial-password'
```

Copy the `admin` password and use it to sign in.

Port-forward to the ArgoCD server.

```sh
kubectl port-forward service/argocd-server -n argocd 8443:443
```

Open <https://localhost:8443> in a browser and sign in with username `admin` and the password we just created. You can then navigate to the user settings and change the password.

## Use Vault

The `install_argocd` role will deploy an ArgoCD application for managing the Vault Helm deployment.

Exec into a pod and initialize.

```sh
kubectl exec -it vault-0 -n vault -- sh -c 'vault operator init -key-threshold=1 -key-shares=1'
kubectl exec -it vault-0 -n vault -- sh -c 'vault operator unseal <recovery-key>'
```

Now join and unseal the other four Vault pods.

```sh
for pod in (seq 1 4)
    kubectl exec -it vault-$pod -n vault -- sh -c 'vault operator raft join http://vault-0.vault-internal:8200'
    kubectl exec -it vault-$pod -n vault -- sh -c 'vault operator unseal <recovery-key>'
end
```

Setup secrets.

```sh
kubectl create secret generic vault-operator-token --from-literal=token='<root-token>' -n vault
kubectl create secret generic vault-operator-recovery-key --from-literal=key='<recovery-key>' -n vault
```

Port-forward to the ArgoCD server.

```sh
kubectl port-forward service/argocd-server -n argocd 8443:443
```

Now you can [sign into ArgoCD](https://localhost:8443/applications/argocd/vault?view=network&resource=&node=argoproj.io%2FApplication%2Fargocd%2Fvault%2F0&tab=parameters) and update the job property that enables the job that restarts the Vault pods after each Helm upgrade. Click `Edit` and change `job.enabled` to `true`. Click synchronize to roll out a Helm upgrade. A job will kick off to restart the pods in the correct order and timing.

Anytime you want to unseal all of the pods you can run,

```sh
for pod in (kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n')
    kubectl exec -it $pod -n vault -- sh -c 'vault operator unseal <recovery-key>'
end
```

You can also `cd` into the `vault` directory to run additional tasks. See `task --list`.
