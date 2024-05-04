FROM ubuntu:latest

RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
COPY acceptance/ssh_server/keys/public/id_rsa.pub /root/.ssh/authorized_keys

RUN mkdir /app
WORKDIR /app

CMD ["/usr/sbin/sshd", "-D"]
