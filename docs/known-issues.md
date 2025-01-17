# Known Issues

This document contains a list of known issues that runway has. If you have a problem that is not listed here, please open an issue.

## Remote Command Deployments

This section documents known issues or potential problems with the remote command deployment strategy (SSH).

Runway uses the [ssh2](https://github.com/spider-gazelle/ssh2.cr) crystal library to facilitate SSH connections. In this section, when we refer to `libssh2`, we are referring to the underlying C library that the `ssh2` crystal library uses. When we refer to `ssh2`, we are referring to the crystal library.

### Dependency on `libssh2`

This library has a direct dependency on the `libssh2` library. If you are having issues with runway not being able to connect to your servers, you may need to install `libssh2` on your system.

#### MacOS

```bash
brew install libssh2
```

#### Linux

```bash
# if you have linuxbrew
brew install libssh2
```

```bash
# you might need to dev packages for libssh2 even if you ran the above command for libssh2
apt-get install libssh2-1-dev
```

### Dependency on `libevent`

This library has a direct dependency on the `libevent` library. You may need to install it on your system.

```bash
sudo apt-get install libevent-dev
```

### Public Key Authentication Failures

This section describes possible problems you may run into when using public key authentication with the remote command deployment strategy, and how to fix them.

#### Permissions Issues

The most common reason why you may see errors like `SSH2::SessionError - ERR -18: Username/PublicKey combination invalid` is because the public/private key pair you are using has incorrect permissions.

Please make sure that your keys have the correct permissions. In general, this usually means something like this:

- The containing directory should have permissions `700`
- The private/public key pair should have permissions `600`

The `acceptance/` dir at the root of this repo actually spins up an SSH server, and a container running runway and runs deployment commands on that SSH server. If you are having issues with the `remote_command` deployment strategy, looking at how this is setup in the `acceptance/` dir may help you debug your issues.

#### RSA Algorithm Issues

RSA is kind of a dated algorithm, and some SSH servers may not support it. If you are having issues with RSA keys, you may want to try using an ECDSA key instead.

However, many systems are still using RSA keys, so this is a real issue many users may run into.

You may see `SSH2::SessionError - ERR -18: Username/PublicKey combination invalid` if you are having RSA key issues which is unfortunate because the error message is not very helpful and it actually obfuscates the real issue.

Let's say you generated a key with:

```bash
ssh-keygen -m PEM -t rsa
```

If you look at the logs on the remote server that `runway` is trying to SSH into, you might see this:

```console
$ cat /var/log/auth.log
...
userauth_pubkey: signature algorithm ssh-rsa not in PubkeyAcceptedAlgorithms [preauth]
...
```

To fix this problem, you need to tell the SSH server to accept RSA keys. You can do this like so:

Open and edit: `/etc/ssh/sshd_config`

```bash
sudo nano /etc/ssh/sshd_config
```

Add the following line:

```ini
PubkeyAcceptedAlgorithms +ssh-rsa
```

Restart the ssh service:

```bash
sudo service ssh restart
```

Now you SSH connections with your RSA should succeed.

> This is a known and documented issue in the ssh2 library - [issue](https://github.com/spider-gazelle/ssh2.cr/issues/16)
