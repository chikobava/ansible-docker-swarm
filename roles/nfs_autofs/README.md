# Role: nfs_autofs

Mount remote NFS shares on-demand using `autofs`.

This role installs and configures `autofs` to mount NFS shares from a remote NFS server dynamically under a specified mount point. It supports multiple subdirectories, configurable ownership, and permissions for each mount.

## Requirements

- An operational NFS server
- Tested on CentOS 10 Stream
- SSH access to managed nodes

## Role Variables

### Required

| Variable | Description | Default |
|---------|-------------|---------|
| `nfs_autofs_remote_server` | IP or hostname of the remote NFS server | `192.168.163.136` |
| `nfs_autofs_remote_mount_folder` | Remote NFS path to be mounted on the client | `/srv/nfs/docker` |
| `nfs_autofs_local.auto_master_path` | Local base mount path for autofs | `/mnt/nfs` |
| `nfs_autofs_local.entries` | List of mount entries (subfolders) | See example below |

Each item in `nfs_autofs_local.entries` should include:

- `name`: Subdirectory name (used under the mount point)
- `owner`: Local ownership (default: `root`)
- `group`: Local group ownership (default: `root`)
- `mode`: Directory permissions (default: `0755`)
- `remote_path`: Remote directory path on the NFS server

### Example

```yaml
nfs_autofs_local:
  auto_master_path: "/mnt/nfs"
  entries:
    - name: "docker"
      owner: "admin"
      group: "admin"
      mode: "0755"
      remote_path: "/srv/nfs/docker"

nfs_autofs_remote_server: 192.168.163.136
nfs_autofs_remote_mount_folder: "/srv/nfs/docker"
```
### Example playbook
```yaml
- hosts: nfs_clients
  become: true
  roles:
    - role: nfs_autofs
```
### Templates Used
- `auto.master.j2` configures the master autofs map to mount under {{ nfs_autofs_local.auto_master_path }}

- `auto.nfs.j2` defines individual mount entries from nfs_autofs_local.entries

Generated entries will look like:

`/mnt/nfs/docker → 192.168.163.136:/srv/nfs/docker`


### Dependencies
None

### Licence
MIT