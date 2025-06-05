# swarm_common

This role installs and configures Docker on Swarm manager and worker nodes. It handles required dependencies, sets up the Docker repository, installs the engine, and ensures the Docker service is running.

## Requirements

- CentOS 10 / Rocky / RHEL-compatible distribution
- Network access to Docker's official repository
- User privileges to install system packages (`become: true` is used)

## Role Variables

```yaml
# defaults/main.yml
swarm_common_docker_user: admin
```

| Variable | Description | Default |
|---------|-------------|---------|
| `swarm_common_docker_user` | The system user to add to the Docker group	| `admin` |

### Tasks Performed
- Installs required system packages (e.g., `python3-pip`, `dnf-plugins-core`)
- Installs the Python docker module
- Adds the official Docker repository
- Installs Docker Engine and related tools:
  - `docker-ce`, `docker-ce-cli`, `containerd.io`
  - `docker-buildx-plugin`, `docker-compose-plugin`
- Adds the specified user to the `docker` group
- Enables and starts the Docker service

### Example Playbook

```yaml
- name: Prepare Swarm node
  hosts: swarm_nodes
  become: true
  roles:
    - role: swarm_common
      vars:
        swarm_common_docker_user: admin
```

### Dependencies
None

### License
MIT

