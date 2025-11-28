# Kolla-Ansible OpenStack Workshop — Command Summary - Unipi 2025

This document summarizes all commands used throughout the workshop, grouped by topic for clarity.

---

## 1. Connecting to Your Machine

```bash
# To SSH into your assigned VM:
ssh e4user@<IP_received_in_email>
```
> A password will be requested, it can be found in the e-mail.

---

## 2. System Information & Network Checks

```bash
# To check for the network interfaces:
ip -br -c a
```

---

## 3. Preparing the Ansible Environment

```bash
# To create and activate a Python virtual environment:
cd /openstack/e4user
python3 -m venv kolla_env
source kolla_env/bin/activate
# To install the required Python packages:
pip install -U pip docker pkgconfig dbus-python
pip install git+https://opendev.org/openstack/kolla-ansible@stable/2025.1
```

---

## 4. Preparing Kolla Directory Structure

```bash
# To create Kolla configuration directory:
sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla
# To copy the example configuration files:
cp -r kolla_env/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp kolla_env/share/kolla-ansible/ansible/inventory/all-in-one .
```

---
## 5. Edit the globals.yml

To edit the /etc/kolla/globals.yml use:
```bash
nano /etc/kolla/globals.yml
```

Add the following:
```bash
kolla_base_distro: "ubuntu"
################ MODIFY THE VAR BELOW ################
kolla_internal_vip_address: "ens4_ip + 1" # <<- Use: ip -br -c a
################ MODIFY THE VAR ABOVE ################
network_interface: "ens4"
neutron_external_interface: "veth-ovs"
enable_cinder: "true"
enable_cinder_backend_lvm: "true"
openstack_release: "2025.1"
docker_registry: "10.0.1.120:4000"
docker_registry_insecure: "yes"
docker_namespace: "openstack.kolla"
```
 
> MODIFY THE VARIABLE "kolla_internal_vip_address"!!!
> To get "ens4_ip" use "ip -br -c a"


---

## 6. LVM Backend Setup (for Cinder)


```bash
# To create the pv and the vg:
sudo pvcreate /dev/vdb
sudo vgcreate cinder-volumes /dev/vdb
# To verify the create volume group:
sudo vgs
```

---

## 7. Kolla-Ansible Deployment Workflow

```bash
# To install dependencies:
kolla-ansible install-deps
# To generate passwords:
kolla-genpwd
# To view generated passwords:
cat /etc/kolla/passwords.yml
# To bootstrap servers:
kolla-ansible bootstrap-servers -i ./all-in-one
# To run prechecks:
kolla-ansible prechecks -i ./all-in-one
# To deploy OpenStack:
kolla-ansible deploy -i ./all-in-one
# To execute Post-deploy:
kolla-ansible post-deploy -i ./all-in-one
# To check for generated OpenStack RC files:
ls /etc/kolla/ | grep admin
```

---

## 8. Inspecting the Deployment

```bash
# To list all running containers (openstack services):
sudo docker ps -a
# To list configuration files and logs:
sudo ls /etc/kolla
sudo ls /var/log/kolla
# To check the created LVM volumes:
sudo lvs
```

---

## 9. OpenStack Administration

```bash
# To install the OpenStack CLI:
pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/master
# To source the admin credentials:
source /etc/kolla/admin-openrc.sh
# To see all services endpoints:
openstack endpoint list
# To initialize the basic resources:
./init-runonce.sh
# To destroy the basic resources:
./destroy.sh
# To list created servers:
openstack server list
# To connect to the created instance:
ssh -i /openstack/e4user/keys/instanceKey cirros@<IP>
```

---

## ADDITIONAL. Reconfiguring OpenStack — NFS Backend

```bash
# To create the Kolla config directory:
mkdir -p /etc/kolla/config
# To Provide NFS share information:
echo "10.0.1.120:/openstack/nfs" | tee "/etc/kolla/config/nfs_shares"
# To activate the Python environment:
source /openstack/e4user/venv/bin/activate
# To reconfigure only the Cinder service:
kolla-ansible reconfigure -t cinder -i ./all-in-one
# To verify how many active cinder-volume services:
openstack volume service list
```
