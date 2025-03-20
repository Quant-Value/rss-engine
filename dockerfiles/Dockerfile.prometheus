FROM ubuntu/prometheus:2-24.04_stable

# Cambiamos a usuario root para instalar sudo y configurar
USER 0

# Actualizamos e instalamos sudo
RUN apt update && apt install -y sudo

# Permitimos que el usuario ubuntu use sudo sin contraseña
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu

# Cambiamos al usuario ubuntu
USER ubuntu

# Anulamos el ENTRYPOINT heredado para que no intente usar "pebble"
ENTRYPOINT []



