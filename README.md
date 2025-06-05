# ansible-docker-swarm
An Ansible-based setup for deploying a lightweight Docker Swarm cluster with NFS-backed shared storage.
This repository provides a modular, repeatable automation framework to:
- Provision and configure NFS servers and clients for shared storage
- Initialize and manage Docker Swarm clusters with manager and worker nodes
- Automate common cluster setup tasks using Ansible roles and playbooks

### Features
- NFS Server & Client Roles: Set up export directories, permissions, and firewall rules, with dynamic client configurations.
- Swarm Common Role: Installs Docker Engine and required dependencies, configures users and starts Docker.
- Swarm Manager & Worker Playbooks: Initialize and join nodes to the Docker Swarm cluster using secure tokens.
- Idempotent, modular design: Easily extend or customize for your infrastructure.
- Firewall and service management: Ensures proper services are running and accessible.


### Prerequisites
- Managed hosts running CentOS 10 Stream (or compatible)
- SSH access with privilege escalation (become: true)
- Proper network connectivity between NFS servers, clients, and swarm nodes
- Docker installed (managed via roles in this repo)


### Installation & Usage
Install required Ansible collections
```bash
ansible-galaxy collection install community.docker
```

### Run the full cluster setup
Use the top-level install_cluster.yml playbook to set up the NFS server, prepare swarm nodes, and initialize the Docker Swarm cluster:
```bash
ansible-playbook -i inventories/dev/inventory-all.yml install_cluster.yml --become
```
**Note**:
Please adjust the inventory file `inventories/dev/inventory-all.yml` as needed to match your environment.


This playbook runs in stages:
1. Setup NFS Server (nfs_server role)
2. Prepare Swarm Manager nodes (install NFS client, autofs, Docker)
3. Prepare Swarm Worker nodes (install NFS client, autofs, Docker)
4. Initialize the Swarm cluster on manager nodes
5. Join worker nodes to the cluster

### Repository Structure
- `roles/nfs_server/` — NFS server installation and export configuration
- `roles/nfs_client/` — NFS client setup and services
- `roles/nfs_autofs/` — Automount configuration for NFS shares
- `roles/swarm_common/` — Docker installation and setup for all nodes
- `playbooks/swarm/tasks/` — Tasks for managing swarm managers and workers
- `install_cluster.yml` — Orchestrates the entire cluster deployment

### Notes & Best Practices
- All tasks use privilege escalation (become: true) to ensure proper permissions.
- Firewall ports and services are managed automatically.
- NFS exports and Docker Swarm tokens are dynamically handled to support multi-node setups.
- Designed to be idempotent and safe for repeated runs.

### Dependencies
- `community.docker`

To install the required Ansible collection, run:

```bash
ansible-galaxy collection install community.docker
```

### License
MIT License