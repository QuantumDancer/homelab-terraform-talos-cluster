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
cat ~/.ssh/id_ed25519 # Note down for later
```

### Terraform Configuration

Set the following variables, either via a `.tfvars` file or via environment variables (`TF_VAR_*`).

```terraform
proxmox_endpoint  = "https://<proxmox-address>:8006"
proxmox_api_token = "terraform@pve!provider=<token>"
proxmox_username  = "terraform"
proxmox_ssh_private_key = <<-EOF
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
EOF
```
