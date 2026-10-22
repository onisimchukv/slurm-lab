# Slurm lab: Ansible role for a 3-node Rocky Linux 9 cluster

Builds a small Slurm cluster: one controller (`slurmctld`, `slurmdbd`, MariaDB, NFS server) and two or more compute nodes (`slurmd`). It also creates sample partitions, accounts, a QoS and two test users so you can practise fair-share, QoS and accounting straight away.

## What you get

| Piece | Where |
| --- | --- |
| munge authentication, key generated once and distributed | all nodes |
| MariaDB and `slurmdbd` accounting | controller |
| `slurmctld` with backfill and multifactor priority | controller |
| `slurmd` with cgroup enforcement | compute nodes |
| `/shared` over NFS (job output, examples) | controller exports, compute mounts |
| Partitions `debug`, `long`, `gpu`, accounts `physics`, `biomed`, QoS `gpu_short`, users `alice`, `bob` | `group_vars/all/main.yml` |
| Simulated GPUs (`gres/gpu`, 2 per node) | compute nodes |

## Prerequisites

1. Three Rocky Linux 9 VMs (for example on Synology VMM): `ctl` with 2 vCPU and 3 GB RAM, `c1` and `c2` with 4 vCPU and about 6 GB RAM each.
2. SSH access with a sudo-capable user from the machine running Ansible.
3. Ansible 2.14 or newer on your workstation.

## Run it

```bash
cd slurm-lab
ansible-galaxy collection install -r requirements.yml

# 1. Set addresses and SSH user
$EDITOR inventory/hosts.yml

# 2. Set the accounting database password (encrypted)
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
$EDITOR group_vars/all/vault.yml
ansible-vault encrypt group_vars/all/vault.yml

# 3. Check connectivity, then build
ansible all -m ping
ansible-playbook site.yml --ask-vault-pass

# 4. Verify with real jobs
ansible-playbook verify.yml --ask-vault-pass
```

Run a subset with tags: `--tags munge`, `--tags config`, `--tags accounting`. The whole play is idempotent, so a second run should report no changes.

## Try it by hand

```bash
ssh ctl
sudo -iu alice
cd /shared/alice
sinfo -Nl
sbatch /shared/examples/array_job.sh
sbatch /shared/examples/gpu_job.sh
squeue -o "%i %P %u %T %r"
sacct -X -o JobID,Partition,Account,QOS,AllocTRES%30,State
sshare -a
sprio -l
```

Fair-share exercise: submit a batch of jobs as `alice`, then as `bob`, and watch `sshare -a` and `sprio -l` change as usage accumulates.

## Variables you are likely to change

| Variable | Purpose |
| --- | --- |
| `slurm_node_cpus`, `slurm_node_memory_mb` | Must not exceed what a node really has; check with `slurmd -C` |
| `slurm_gpu_count`, `slurm_gpu_simulated` | GPUs per node; set simulated to `false` on real NVIDIA hardware |
| `slurm_partitions`, `slurm_accounts`, `slurm_qos`, `slurm_users` | Scheduling policy and test population |
| `slurm_firewall_trusted_cidr` | Lab subnet to trust in firewalld, for example `192.168.1.0/24` |
| `slurm_selinux_mode` | Defaults to `permissive` for the lab |

## Known limits and honest caveats

- **Packages come from EPEL.** Names and versions can differ between releases; adjust `slurm_packages_*` if `dnf` cannot find one. For a production-style build you would compile Slurm from SchedMD's release tarball into your own RPMs and host them in an internal repository.
- **GPUs are simulated.** Scheduling, QoS limits and accounting behave realistically, but there is no device isolation. Real GPUs need NVIDIA drivers and a Slurm build with NVML.
- **SELinux is set to permissive** and the firewall handling is minimal. Both are lab shortcuts; say so if asked.
- **No high availability.** One controller and a local database; a production site would use a backup controller, a separate database host, a parallel filesystem and monitoring.
- **Not yet run end to end against live VMs.** The role was written to be correct and syntax checked, but first-run issues such as a package name or memory size are likely. Use `verify.yml` and the logs in `/var/log/slurm/` to diagnose.

## Main talking points this lab gives you

- Why `slurm` and `munge` UIDs must match on every node, and why clocks must be synced.
- Config management for a scheduler: one `slurm.conf` rendered everywhere from inventory.
- Accounting hierarchy: cluster, account, user, QoS, and how `AccountingStorageEnforce` makes limits real.
- Day-two operations: drain a node (`scontrol update nodename=c2 state=drain reason="maintenance"`), resume it, upgrade `slurmdbd` before `slurmctld`.
- What you would change for production (HA, parallel storage, monitoring, DCGM and real GPUs).
