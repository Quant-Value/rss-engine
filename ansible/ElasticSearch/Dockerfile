FROM docker.elastic.co/elasticsearch/elasticsearch:8.6.0
USER 0
RUN apt update && apt install -y sudo 
RUN echo "elasticsearch ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/elasticsearch
USER elasticsearch