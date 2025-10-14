#!/bin/bash

BASE_IMAGE="quay.io/openstack.kolla"
TAG="2025.1-ubuntu-noble"

IMAGES=(
  horizon
  heat-engine
  heat-api-cfn
  heat-api
  neutron-metadata-agent
  neutron-l3-agent
  neutron-dhcp-agent
  neutron-openvswitch-agent
  neutron-server
  nova-compute
  nova-libvirt
  nova-ssh
  nova-novncproxy
  nova-conductor
  nova-api
  nova-scheduler
  openvswitch-vswitchd
  openvswitch-db-server
  placement-api
  cinder-backup
  cinder-volume
  cinder-scheduler
  cinder-api
  glance-api
  keystone
  keystone-fernet
  keystone-ssh
  rabbitmq
  tgtd
  iscsid
  memcached
  mariadb-server
  keepalived
  proxysql
  haproxy
  cron
  kolla-toolbox
  fluentd
)

for image in "${IMAGES[@]}"; do
  full_image="${BASE_IMAGE}/${image}:${TAG}"
  echo "Pulling ${full_image}..."
  sudo docker pull "${full_image}"
done