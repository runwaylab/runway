# Deployments

Deployments are triggered by events and define how your "project" gets deployed. Deployments are generally commands that runway executes.

This document goes over the different types of deployments that runway can handle for and how to configure them.

All event example configurations assume that you are extending an example configuration like this one:

```yaml
projects:
  - name: project-1
    # this is the relevant part for this page
    deployment: # the deployment configuration to run when an event is triggered (only one deployment per project)
      # details in each section below
    events:
      # ...
```

## Command Deployment

Command deployments are the only deployment types supported currently. They run a command on the **local** machine or **remote** server (via SSH). Runway will execute the command using the specified entrypoint and arguments.

A very helpful feature of command deployments is the `success_string` field. This field allows you to specify a string that runway will look for in the output of the command. If the string is found, the deployment is considered successful. If the string is not found, the deployment is considered a failure.

### Local

Local commands are executed directly on the host by runway. This is useful for running commands that don't require a remote connection (SSH).

If you are running runway from within a docker container, the host will literally be the container that runway is running in.

If you are running a binary of runway on your local machine, the host will be your local machine.

Usage:

```yaml
type: command # this deployment type runs a command on the local machine or remote server (via SSH)
location: local # run the command on the local machine
path: foo/bar # local path to run the command in
timeout: 300 # the maximum time in seconds that a cmd can run before it is killed and the deployment fails - default is 300
entrypoint: bash # the command/binary/entrypoint - like docker syntax!
cmd: ["-c", "echo 'hello world' > test-example.txt"] # the command to run using the entrypoint - like docker syntax!
```

### Remote

Remote commands are executed on a remote server via SSH. This is useful for running commands on a server that runway has access to.

For example, you could use this to deploy a new version of your application to a server that you have SSH access to.

Usage:

```yaml
type: command # this deployment type runs a command on the local machine or remote server (via SSH)
location: remote # run the command on a remote server via SSH
remote: # configuration block to establish an SSH connection to the remote server
  auth: publickey # the authentication method to use (`login`, `publickey`, or `agent`)
  host: 'server.example.com' # the hostname or IP address of the remote server
  port: 22 # the port to connect to on the remote server
  username: ubuntu # the username to use to connect to the remote server
  public_key_path: /runway/keys/id_rsa.pub # the path to the public key to use for authentication (must be accessible to runway)
  private_key_path: /runway/keys/id_rsa # the path to the private key to use for authentication (must be accessible to runway)
success_string: complete-remote # the string to look for in the output of the command to determine if the deployment was successful
timeout: 5 # the maximum time in seconds that a cmd can run before it is killed and the deployment fails - default is 300
entrypoint: bash # the command/binary/entrypoint - like docker syntax!
cmd: ["-c", "'echo path: {{ payload.path }} > /app/logs/result-remote.txt && echo complete-remote'"] # the command to run, wrap it in single quotes because character escaping is hard :(
```

The following remote connection types are supported:

- `login`: Use a username and password to connect to the remote server
- `publickey`: Use a public/private key pair to connect to the remote server (yeah you need to provide both keys because the underlying library is weird)
- `agent`: Use an SSH agent to connect to the remote server

Note: If you are using `publickey` authentication, you will need to provide both the public and private key paths. These key paths must be accessible to runway. If you are running runway from within a docker container, you will need to mount the keys into the container. Please also review the [known issues](./known-issues.md) document to ensure that you have the correct permissions set on your keys.

### Payload Interpolation

You can use the `{{ payload.key }}` syntax to interpolate values from the payload into your command. This is useful for passing data from an event into a deployment.

The full list of `payload` attributes that _might_ be available to use can be found [here](../src/runway/models/deployment_payload.cr). The reason that we say "might" is because the payload is event-specific and not all events will have the same payload attributes set. For example, a `github_deployment` event will have different payload attributes than a `file` event. A GitHub deployment event will have `repo`, `environment`, and `sha` / `ref` attributes, while a file event will not

This can be incredibly useful for passing data from an event into a deployment. For example, you could do something like this for your remote deployment command:

```yaml
cmd: ["-c", "'script/deploy --ref {{ payload.ref }}'"]
```

This would pass the `ref` attribute that was set from the `github_deployment` event into the `script/deploy` script on the remote server. Pretty neat!
