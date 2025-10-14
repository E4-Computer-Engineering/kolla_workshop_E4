#!/bin/bash

REGISTRY="10.0.100.152:4000"

# Loop through all kolla images
sudo docker image ls --format "{{.Repository}}:{{.Tag}}" | grep quay.io/openstack.kolla | while read image; do
    # Extract image name after "quay.io/"
    base_name=$(echo "$image" | cut -d'/' -f3)
    new_image="$REGISTRY/openstack.kolla/$base_name"

    echo "Tagging $image -> $new_image"
    sudo docker tag "$image" "$new_image"

    echo "Pushing $new_image"
    sudo docker push "$new_image"
done