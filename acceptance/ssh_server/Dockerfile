FROM ubuntu:latest

USER root

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
COPY --chown=root:root acceptance/ssh_server/keys/public/id_rsa.pub /root/.ssh/authorized_keys

# Uncomment or add necessary lines in sshd_config
RUN sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo 'PubkeyAcceptedKeyTypes=+ssh-rsa' >> /etc/ssh/sshd_config

RUN mkdir /app
WORKDIR /app

CMD ["/usr/sbin/sshd", "-D"]
