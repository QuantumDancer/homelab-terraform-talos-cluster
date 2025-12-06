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

## Initial cluster creation

Run the following commands:

```bash
terraform init
terraform plan
terraform apply
```

After successful deployment, retrieve the Talos and Kubernetes configuration:

```bash
source ./scripts/activate_configs.sh
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
