docker run -it --rm -v /mnt/e/Campusdual/Grupal-repos/imatia-rss-engine/scripts/cloud:/app/scripts -v /mnt/e/Campusdual/Grupal-repos/imatia-rss-engine/scripts/.aws:/root/.aws --entrypoint /bin/bash my-flexvega-image

docker build -t my-flexvega-image -f ./Dockerfile.worker .



sudo curl -o /home/ubuntu/play/docker-compose.yml.j2 https://raw.githubusercontent.com/campusdualdevopsGrupo2/imatia-rss-engine/refs/heads/main/ansible/SW_Worker/docker-compose-workers.yml.j2

sudo docker run --rm -v /home/ubuntu/play:/ansible/playbooks -v /home/ubuntu/.ssh:/root/.ssh \
--network host -e ANSIBLE_HOST_KEY_CHECKING=False -e ANSIBLE_SSH_ARGS="-o StrictHostKeyChecking=no" \
--privileged --name ansible-playbook-container \
--entrypoint "/bin/bash" ansible-local  -c "ansible-playbook -i /ansible/playbooks/hosts.ini /ansible/playbooks/install2.yml -e DNS_SERVER=$(cat /etc/dns_name) -e ENVIRON=demo -e SECRET_NAME=$(cat /etc/secret_name) "
