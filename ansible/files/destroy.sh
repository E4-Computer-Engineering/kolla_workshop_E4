#!/bin/bash

set -o errexit
set -o pipefail

KOLLA_CONFIG_PATH=${KOLLA_CONFIG_PATH:-/etc/kolla}
KOLLA_OPENSTACK_COMMAND=openstack

# Load credentials
if [[ ! -f ${KOLLA_CONFIG_PATH}/admin-openrc.sh ]]; then
    echo "Missing admin-openrc.sh"
    exit 1
fi

source ${KOLLA_CONFIG_PATH}/admin-openrc.sh

echo "Starting cleanup of init.sh resources..."

VM_NAME=${VM_NAME:-'demo-vm'}
IMAGE_NAME=cirros
EXT_NET_NAME=${EXT_NET_NAME:-public}

############################################
# Delete server + floating IP
############################################
if $KOLLA_OPENSTACK_COMMAND server show "$VM_NAME" &>/dev/null; then
    echo "Deleting server ${VM_NAME}..."
    $KOLLA_OPENSTACK_COMMAND server delete "$VM_NAME"
fi

FLOATING_IP=$($KOLLA_OPENSTACK_COMMAND floating ip list -c "Floating IP Address" -f value || true)
if [[ -n "$FLOATING_IP" ]]; then
    echo "Deleting floating IP: $FLOATING_IP"
    $KOLLA_OPENSTACK_COMMAND floating ip delete "$FLOATING_IP"
fi

###########################################
# Delete security group rules added to default
############################################
ADMIN_PROJECT_ID=$($KOLLA_OPENSTACK_COMMAND project list | awk '/ admin / {print $2}')
ADMIN_SEC_GROUP=$($KOLLA_OPENSTACK_COMMAND security group list --project ${ADMIN_PROJECT_ID} | awk '/ default / {print $2}')

if [[ -n "$ADMIN_SEC_GROUP" ]]; then
    echo "Deleting ICMP and SSH rules from default security group..."

    for RULE in $($KOLLA_OPENSTACK_COMMAND security group rule list -f value -c ID -c "IP Protocol" -f value | grep -Ei "tcp|icmp" | awk {'print $1'}); do
            $KOLLA_OPENSTACK_COMMAND security group rule delete "$RULE"
    done
fi

############################################
# Delete keypair created
############################################
if $KOLLA_OPENSTACK_COMMAND keypair show mykey &>/dev/null; then
    echo "Deleting keypair mykey..."
    $KOLLA_OPENSTACK_COMMAND keypair delete mykey
fi

############################################
# Delete networks + router
############################################
if $KOLLA_OPENSTACK_COMMAND router show demo-router &>/dev/null; then
    echo "Removing router interface & external gateway..."
    $KOLLA_OPENSTACK_COMMAND router unset --external-gateway demo-router || true
    $KOLLA_OPENSTACK_COMMAND router remove subnet demo-router demo-subnet || true
    echo "Deleting router demo-router..."
    $KOLLA_OPENSTACK_COMMAND router delete demo-router
fi

if $KOLLA_OPENSTACK_COMMAND subnet show demo-subnet &>/dev/null; then
    echo "Deleting subnet demo-subnet..."
    $KOLLA_OPENSTACK_COMMAND subnet delete demo-subnet
fi

if $KOLLA_OPENSTACK_COMMAND network show demo-net &>/dev/null; then
    echo "Deleting network demo-net..."
    $KOLLA_OPENSTACK_COMMAND network delete demo-net
fi

# External network created by init.sh
if $KOLLA_OPENSTACK_COMMAND network show "$EXT_NET_NAME" &>/dev/null; then
    # Check if subnet exists
    if $KOLLA_OPENSTACK_COMMAND subnet show "${EXT_NET_NAME}-subnet" &>/dev/null; then
        echo "Deleting external subnet ${EXT_NET_NAME}-subnet..."
        $KOLLA_OPENSTACK_COMMAND subnet delete "${EXT_NET_NAME}-subnet"
    fi
    echo "Deleting external network ${EXT_NET_NAME}..."
    $KOLLA_OPENSTACK_COMMAND network delete "$EXT_NET_NAME"
fi

############################################
# Delete cirros image
############################################
if $KOLLA_OPENSTACK_COMMAND image show "$IMAGE_NAME" &>/dev/null; then
    echo "Deleting image ${IMAGE_NAME}..."
    $KOLLA_OPENSTACK_COMMAND image delete "$IMAGE_NAME"
fi

############################################
# Delete flavors
############################################
for FLAVOR in m1.tiny m1.small m1.medium m1.large m1.xlarge m2.tiny; do
    if $KOLLA_OPENSTACK_COMMAND flavor show "$FLAVOR" &>/dev/null; then
        echo "Deleting flavor $FLAVOR..."
        $KOLLA_OPENSTACK_COMMAND flavor delete "$FLAVOR"
    fi
done

############################################
# Optional: delete local image + keys
############################################
echo "Cleaning local artifacts..."

rm -f /openstack/e4user/keys/instanceKey /openstack/e4user/keys/instanceKey.pub || true

# Remove downloaded cirros image if present
CIRROS_RELEASE=${CIRROS_RELEASE:-0.6.2}
ARCH=$(uname -m)
IMAGE=cirros-${CIRROS_RELEASE}-${ARCH}-disk.img
rm -f "./${IMAGE}" /opt/cache/files/${IMAGE} || true

echo "All resources created by init.sh have been removed."

