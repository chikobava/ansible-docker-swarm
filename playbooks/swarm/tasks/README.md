# Playbook: swarm_managers.yml

This playbook initializes and manages a Docker Swarm cluster on the designated manager nodes.

## Purpose

- Check if the Docker Swarm is already initialized
- Initialize Swarm on the first manager node if not already done
- Retrieve and distribute manager and worker join tokens
- Join nodes to the Swarm cluster as managers
- Promote nodes to manager role if necessary
- Enable firewall rules for Docker Swarm

## Hosts

- Targeted group: `swarm_managers`

## Requirements

- Docker installed on all nodes
- Python `docker` SDK installed (managed by roles)
- Sufficient privileges (`become: true` when running playbook)
- Proper networking between nodes

## Variables

- Uses Ansible facts and `hostvars` to manage tokens and IP addresses dynamically.
- No explicit user variables required.

## Running the Playbook

```bash
ansible-playbook playbooks/swarm/tasks/swarm_managers.yml -i inventories/dev/inventory-all.yml --become
```

### Tasks Summary
- Fetch current node swarm info
- Initialize Swarm if not already initialized
- Set manager and worker tokens as facts
- Join nodes to Swarm
- Promote nodes to managers if applicable
- Configure firewall rules for Swarm

### Dependencies

- `community.docker`

To install the required Ansible collection, run:

```bash
ansible-galaxy collection install community.docker
```

# Playbook: swarm_workers.yml

This playbook joins target nodes to an existing Docker Swarm cluster as worker nodes.

## Purpose

- Retrieve the worker join token and manager IP from the Swarm managers
- Join the current node to the Swarm cluster as a worker

## Hosts

- Targeted group: `swarm_workers`

## Requirements

- Docker installed on all nodes
- Docker Swarm initialized on at least one manager node
- Proper network connectivity between worker nodes and the swarm manager
- `become: true` privileges when running the playbook

## Variables

- `worker_token` and `swarm_manager_ip` are extracted dynamically from the first manager node in `swarm_managers` group.

## Running the Playbook

```bash
ansible-playbook playbooks/swarm/tasks/swarm_workers.yml -i inventories/dev/inventory-all.yml --become
```

### Tasks Summary
- Extract worker join token and swarm manager IP address (runs once)
- Join node to Docker Swarm as a worker using the retrieved token

For a full cluster installation example, see `install_cluster.yml` at the root of the repository.
