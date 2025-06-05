# Role: nfs_server

This role installs and configures an NFS server, sets up export directories, and ensures proper permissions and firewall settings are applied. It supports multiple export paths and client configurations via Ansible variables.

## Requirements

- Tested on CentOS 10 Stream
- Firewalld must be available and running
- Requires root privileges (via `become: true`)

## Role Variables

All variables are defined in `defaults/main.yml`.

```yaml
nfs_server_nfs_exports:
  - path: "/srv/nfs/docker"
    clients:
      - "192.168.163.0/24(rw,sync,no_root_squash)"
    owner: "admin"
    group: "admin"
    mode: "0755"
```

| Variable                     | Description                                                      | Default               |
|------------------------------|-----------------------------------------------------------------|-----------------------|
| `nfs_server_nfs_exports.path`  | Directory to export via NFS                                     | `/srv/nfs/docker`     |
| `nfs_server_nfs_exports.clients` | List of client definitions in exports format (e.g. IP(range)(options)) | `["192.168.163.0/24(rw,sync,no_root_squash)"]` |
| `nfs_server_nfs_exports.owner`  | Owner of the export directory                                   | `admin`               |
| `nfs_server_nfs_exports.group`  | Group of the export directory                                   | `admin`               |
| `nfs_server_nfs_exports.mode`   | Filesystem permissions (e.g. 0755)                             | `0755`                |

You can define multiple export blocks to support multiple shares.

### Tasks Performed

- Installs required NFS server packages (nfs-utils)
- Creates and configures export directories
- Generates /etc/exports from template
- Starts and enables NFS and RPC services
- Opens NFS-related services in the firewall
- Reloads NFS exports when changes are made

### Example Playbook
```yaml
- hosts: nfs_servers
  become: true
  roles:
    - role: nfs_server
```

### Handler
- reload nfs exports: Reloads NFS export table using `exportfs -ra`

### Dependencies
None

### License
MIT