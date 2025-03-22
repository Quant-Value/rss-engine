docker run -it --rm -v /mnt/e/Campusdual/Grupal-repos/imatia-rss-engine/scripts/cloud:/app/scripts -v /mnt/e/Campusdual/Grupal-repos/imatia-rss-engine/scripts/.aws:/root/.aws --entrypoint /bin/bash my-flexvega-image

docker build -t my-flexvega-image -f ./Dockerfile.worker .