# Movie Reservation Deployment

Infrastructure provisioning and deployment configurations for [movie_reservation_again](https://github.com/jorge-mells/movie_reservation_again), using Terraform, Ansible and Podman Compose.

## Repository contents

### Containers

The Compose project in `compose/` defines the following services:

| Container | Purpose |
|---|---|
| `movie_reservation` | Movie reservation application API |
| `db` | MySQL database |
| `reverseproxy` | Nginx reverse proxy |
| `acme-companion` | Automatic Let's Encrypt certificate management |

The project also defines persistent volumes for database data, certificates and Nginx configuration, with separate application-facing and database networks.

### Infrastructure (Terraform)

The `terraform/` directory contains infrastructure configurations for Hetzner Cloud and local libvirt deployments.

**Hetzner Cloud (`terraform/hetzner/`)**

Creates:
- Private network and subnet.
- Firewall with SSH, HTTP, HTTPS and ICMP ingress rules.
- SSH key registration.
- Virtual machines with cloud-init configuration.
- Ansible inventory resources for the provisioned machines.

**Libvirt (`terraform/libvirt/`)**

Creates:
- NAT-enabled virtual network with DHCP reservations.
- Cloud-init disks.
- VM root disks.
- KVM virtual machines.
- Ansible inventory configuration.

The active Terraform module is selected in `terraform/main.tf`. Hetzner is currently enabled by default.

### Configuration management (Ansible)

The `ansible/` directory contains two roles:

**`security`**
- Applies system updates.
- Configures automatic security updates.
- Installs and configures Fail2ban.
- Configures firewalld and enables SSH, HTTP and HTTPS.

**`run`**
- Installs Podman and Docker-compatible tooling.
- Enables the rootless Podman socket.
- Deploys the Compose project and its environment configuration.
- Configures DNS records through Hetzner DNS or a simulated DNS implementation.
- Configures GitHub-based continuous deployment, including deployment SSH keys and target registration.

## Deployment

The repository includes `deploy.sh`, which provides three commands:

| Command | Description |
|---|---|
| `provision` | Provisions infrastructure using Terraform. |
| `configure` | Configures hosts and deploys the application using Ansible. |
| `cleanup` | Cleans up deployment configuration and destroys infrastructure. |

For custom deployments, the main entry points to inspect are:

- **`deploy.sh`** – deployment workflow and orchestration.
- **`terraform/main.tf`** – selects the infrastructure module.
- **`terraform/hetzner/variables.tf`** and **`terraform/libvirt/variables.tf`** – infrastructure configuration.
- **`ansible/site.yml`** – main Ansible playbook and role configuration.
- **`ansible/roles/*/defaults/main.yml`** – role defaults and configurable parameters.

The individual Terraform resource definitions, Ansible tasks and Compose configuration are located alongside these entry points.
