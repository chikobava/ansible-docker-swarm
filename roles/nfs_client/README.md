# Role: nfs_client

Install and configure the NFS client on target nodes.

This role ensures all necessary NFS client components are installed and running. It prepares the system to connect to NFS servers and mount shared filesystems — either manually or via tools like `autofs`.

## Requirements

- Tested on CentOS 10 Stream
- SSH access to managed nodes
- A reachable NFS server on the network

## Role Variables

This role requires no variables. It installs packages and starts required services using default configurations.

## Tasks Performed

- Installs `nfs-utils`
- Enables and starts the `rpcbind` service
- Enables and starts the `nfs-client.target` service

## Example Playbook

```yaml
- hosts: nfs_clients
  become: true
  roles:
    - role: nfs_client
```

### Dependencies
None

### License
MIT