# Talos Cluster on Proxmox

## Initial setup

### API User Setup

Set up a user on Proxmox and generate an API token.

The `Terraform` role for Proxmox is based on the `PVEVMAdmin` role, with an additional `Sys.Modify`, because this is required by the `proxmox_virtual_environment_download_file` resource.

```bash
pveum user add terraform@pve
pveum role add Terraform -privs "Datastore.Allocate,Datastore.AllocateSpace,Datastore.AllocateTemplate,Datastore.Audit,Group.Allocate,Mapping.Audit,Mapping.Use,Pool.Allocate,Pool.Audit,Realm.AllocateUser,SDN.Allocate,SDN.Audit,SDN.Use,Sys.Audit,Sys.Console,Sys.Syslog,User.Modify,VM.Allocate,VM.Audit,VM.Backup,VM.Clone,VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Console,VM.Migrate,VM.Monitor,VM.PowerMgmt,VM.Snapshot,VM.Snapshot.Rollback,Sys.Modify"
pveum aclmod / -user terraform@pve -role Terraform
pveum user token add terraform@pve provider --privsep=0
```

Note down the token for later.

### Linux System User Setup

Create a dedicated system user for Terraform operations on the Proxmox host:

```bash
useradd -m -s /bin/bash terraform
apt update && apt install sudo # sudo is usually not installed on minimal installations
visudo -f /etc/sudoers.d/terraform
```

Add the following content to `/etc/sudoers.d/terraform`:

```
terraform ALL=(root) NOPASSWD: /sbin/pvesm
terraform ALL=(root) NOPASSWD: /sbin/qm
terraform ALL=(root) NOPASSWD: /usr/bin/tee /var/lib/vz/*
```

Generate SSH key pair for authentication:

```bash
sudo -i -u terraform
ssh-keygen -t ed25519 -C "terraform@proxmox"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp ~/.ssh/id_ed25519.pub ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
cat ~/.ssh/id_ed25519 # Store on local machine
rm ~/.ssh/id_ed25519 # Remove private key from Proxmox
```

### Terraform Configuration

#### Proxmox

Set the following variables, either via a `*.auto.tfvars` file or via environment variables (`TF_VAR_*`).

```terraform
proxmox_endpoint                 = "https://<proxmox-address>:8006"
proxmox_api_token                = "terraform@pve!provider=<token>"
proxmox_username                 = "terraform"
proxmox_ssh_private_key_location = "<path-to-private-ssh-key>"
```

#### Cloudflare

The `talos` module manages the DNS entries for the cluster VIP and for the individual cluster nodes.
This is done via Cloudflare. Create a Cloudflare token that has edit permissions for your DNS zone and
set up the following variables:

```terraform
cloudflare_api_token = "<cloudflare-api-token>"
cloudflare_zone_id   = "<cloudflare-zone-id>"
```

#### ArgoCD

The `argocd` module bootstraps ArgoCD and the root app of the App-of-Apps pattern.
ArgoCD needs access to the GitOps repo that provides the configuration for the root application.

**For private repositories**:

Per default, the GitOps repo is pulled from my private GitLab instance.
Authentication needs to be configured like this:

```terraform
argocd_repo_username = "<username>"
argocd_repo_password = "<password-or-token>"
```

**For public repositories**

To use the public mirror GitHub, overwrite the repo url.
Since this is public, no credentials need to be provided.

```terraform
argocd_repo_url = "https://github.com/QuantumDancer/idp-argocd-platform-apps.git"
```

## Initial cluster creation

On a brand-new cluster, the Cilium Helm provider performs a health check during `terraform plan` that will fail
because the cluster does not exist yet. Target the talos modules first, then apply the rest:

```bash
terraform init
terraform apply -target=module.management_cluster
terraform apply -target=module.talos
# Manual kubelet CSR approval - see below
terraform apply
```

After successful deployment, retrieve the Talos and Kubernetes configuration:

```bash
# Normal cluster
source ./scripts/activate_configs.sh

# Management cluster
source ./scripts/activate_configs.sh
```

### Manual kubelet CSR approval

`serverTLSBootstrap` creates a chicken-and-egg deadlock on fresh clusters: the kubelet serving CSR cannot be
approved until the `kubelet-serving-cert-approver` pod is running, but that pod needs a Ready node, and the node
needs its CSR approved.

Break the cycle manually after the partial apply (`terraform apply -target=...`)

```bash
kubectl get csr
# NAME        AGE     SIGNERNAME                                    REQUESTOR                 REQUESTEDDURATION   CONDITION
# csr-6m6b9   5m14s   kubernetes.io/kubelet-serving                 system:node:mgt1          <none>              Pending
# csr-x8x2m   5m22s   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:1hgl53   <none>              Approved,Issued

kubectl certificate approve csr-6m6b9
# certificatesigningrequest.certificates.k8s.io/csr-6m6b9 approved
```

**Note:** For a multi-node cluster, this needs to be done on all nodes.

After approval, run the full `terraform apply` command.
This will deploy Cilium, which will move the nodes to the `Ready` state.
`kubelet-serving-cert-approver` will eventually start, so any new nodes joining the cluster (or nodes being recycled during updates), will automatically get their certificates approved.

## Gotchas

### Recreating a single-node cluster

When recreating a cluster backed by a single node, taint also the `talos_machine_bootstrap` resource, not only the `proxmox_virtual_environment_vm` resource.
This way, Terraform re-runs the bootstrap step.
The bootstrap state is not reset when only the VM is recreated.

```bash
terraform taint 'module.management_cluster.talos_machine_bootstrap.this'
```

## Maintenance

### Upgrading Talos

1. Set the new Talos version in `cluster.talos_update_version` in the `talos` module call in `main.tf`.
2. **Updates need to be performed sequentially!**
   For each node, set `update` to true and then run `terraform apply`, before changing `update` for the next node.
   Wait until the node has fully rebooted and is operational again (`talosctl -n <node-ip> dashboard`).
3. Set the `cluster.talos_version` option to the same value as `cluster.talos_update_version`.
   Run `terraform apply` again.
4. **Updates need to be performed sequentially!**
   For each node, remote the `update` flag or set it to false and then run `terraform apply`.

### Upgrading Kubernetes

Kubernetes versions will be automatically increased by Renovate Bot. Steps for upgrading Kubernetes:

1. Run `./scripts/update-k8s.sh` to upgrade Kubernetes in a safe way using the Talos API.
2. Run `terraform apply` to update the machine config in the Terraform state.
