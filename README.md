<h2 align="center"><img src="assets/logo.png" alt="logo" align="center" width="200px" /></h1>

<h2 align="center">runway</h1>
<p align="center">
  A self-hosted deployment controller for anything
</p>

<p align="center">
  <a href="https://github.com/runwayapp/runway/actions/workflows/test.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/test.yml/badge.svg?event=push" alt="test" height="18"></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/lint.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/lint.yml/badge.svg?event=push" alt="lint"/></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/acceptance.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/acceptance.yml/badge.svg?event=push" alt="acceptance"/></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/build.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/build.yml/badge.svg?event=push" alt="build"/></a>
  <a href="https://github.com/runwaylab/runway/actions/workflows/docker.yml/badge.svg"><img src="https://github.com/runwaylab/runway/actions/workflows/docker.yml/badge.svg?event=push" alt="build"/></a>
</p>

<p align="center">
  <img src="assets/language-crystal-black.svg" alt="language crystal"/>
  <img src="assets/platforms.svg" alt="platforms amd64 and arm64"/>
  <img src="assets/docker.svg" alt="Dockerized, oh yeah!"/>
</p>

<hr>

## About 💡

Runway is deployment controller that runs on an *event driven system*. You define the **events** that should trigger deployments and then you configure how you want those deployments to be executed. Runway is not a CI/CD system, it is a deployment controller. It is meant to be run on a server that can reach the internet and can also reach your target servers or projects. It can run on the same server as your projects, or on a separate server. It is up to you how you want to configure it.

> See the full project goals [here](docs/original-project-goals.md) for even more information about why this project was created.

## Features 🚀

- 🔍 Event driven system that looks for deployment events that you configure
- ✏️ Configurable - You define the events, how often runway should check for events, and how deployments should be executed
- 📦 Plugable - You can write new deployment strategies or deployment events to extend runway
- 🦾 ARM Support - Runway's pre-built Docker images run on both `x86_64` platforms and `ARM` platforms
- 🚀 Native [github/branch-deploy](https://github.com/github/branch-deploy) support - Runway can look for, and complete GitHub deployments
- 🐳 Fully Dockerized - Runway has [pre-built Docker images](https://github.com/runwaylab/runway/pkgs/container/runway) that make it easy to get started
- 🌱 Small Footprint - Runway is written in [crystal](https://github.com/crystal-lang/crystal) and has a tiny memory footprint. It can even run on a Raspberry Pi 4!

## Quickstart ⭐

This section goes into a brief example of how you can use runway

### Basic Example

Here is a very basic example of using runway:

First, create a runway configuration file (`config.yml`). This config file tells runway how to *run*.

```yaml
# This is a runway configuration file
# config.yml
projects:
  - name: project-1
    deployment: # deployments are actions that get triggered by events
      type: command # this deployment type is a command that gets run
      location: local # the command type is 'local', so the command is executed on the machine by runway
      path: /home/bob/project-1/ # go to this path before running the command
      timeout: 5
      entrypoint: bash
      cmd: ["-c", "echo 'I did a cool deployment!'"] # add your own custom logic here to deploy project-1
    events: # events are actions that can trigger deployments
      - type: file
        path: deploy-it.txt # look for this file and if it's found, trigger the deployment
        cleanup: true # remove the file after the event
        schedule:
          interval: 3s # how often to check for the event
```

Now start runway:

```bash
runway -c config.yml
```

In this example, runway will check for the existence of the `deploy-it.txt` file in the current directory every 3 seconds. If this file is found, that is an *event trigger*. Event triggers kick off the logic defined under the `deployment` section for a given project.

So if we were to create the `deploy-it.txt` file, runway would execute the `command` deployment. The `command` deployment would go to the `/home/bob/project-1/` directory on the `local` system and run `bash -c echo 'I did a cool deployment!'`. After the deployment is complete, the `deploy-it.txt` file gets cleaned up.

You can go ahead and test out this example for yourself to give runway a go!

### Advanced Example

Here is a more complex example of using runway:

First, create a `docker-compose.yml` file which will be responsible for starting runway and mounting a volume that contains your runway configuratin file:

```yaml
# example docker-compose.yml file
services:
  runway:
    container_name: runway
    restart: unless-stopped
    image: ghcr.io/runwaylab/runway:vX.X.X # <--- replace with the tag you want to use
    command: ["-c", "config/config.yml"]
    volumes:
      - keys:/app/keys
      - config:/app/config
    env_file:
      - creds.env

volumes:
  config:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ./config
  keys:
    driver: local
    driver_opts:
      o: bind
      type: none
      device: ./keys
```

Next, create a runway configuration file at `config/config.yml` relative to your `docker-compose.yml` file. This directory gets mounted into runway's container so that your config is accessible to runway.

```yaml
# This is a runway configuration file
# config/config.yml
projects:
  - name: project-1
    deployment:
      type: command # this deployment type will run a command
      location: remote # the location will be "remote" so runway will attempt an SSH connection to the remote server
      remote:
        auth: publickey # the auth mode will be via a public/private key pair to the remote server (SSH)
        host: "192.168.1.5" # this is the host to SSH into - perhaps another host on your home network
        port: 22 # the port to use for SSH connections
        username: ubuntu # the username of the system you want to SSH to
        public_key_path: /app/keys/id_rsa.pub # the public key from the "keys" volume to use for public key auth
        private_key_path: /app/keys/id_rsa # the corresponding private key of the public/private key pair
        success_string: deployment-complete # the string to look for in the command's output to determine if the deployment was successful
      timeout: 30 # the total SSH / command timeout for execution
      entrypoint: bash # the entrypoint of the command to run on the remote host
      cmd: ["-c", "'script/deploy --ref={{ payload.ref }} && echo deployment-complete'"] # the actual command arguments to run
    events: # events that runway looks for to trigger a deployment
      - type: github_deployment # github deployment event
        repo: runwaylab/test-flight # the repository to check for deployment events
        environment: production # the specific environment to check for
        deployment_filter: 1 # only look at the most recent deployment (based on the created_at field) - this field is required only for the github_deployment type event. It helps to save on API requests to GitHub. If not provided, it defaults to 1
        schedule:
          interval: 15s # intervals can be in milliseconds, seconds or minutes (ms, s, or m) - or a cron expression
          timezone: UTC # the timezone to use for the schedule (default is UTC) - ex: Europe/Berlin or America/New_York - see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
      - type: github_deployment # here we define another event to look for, in this case we also check the staging environment
        repo: runwaylab/test-flight
        environment: staging
        deployment_filter: 1
        schedule:
          interval: 5s
          timezone: UTC
```

Now we need to create a `keys/` directory that contains our public/private key pair that we need for runway to SSH into the remote host we defined above.

> Please ensure the `keys/` dir has 700 permissions and your public/private keys have 600 permissions

We also need to create a `creds.env` file which contains a GitHub PAT that is scoped to allow `read` access to `deployments` since our configuration is specifically looking for GitHub deployments. You may also need `repo` permissions on the token as well if your repository is private.

```ini
# creds.env
GITHUB_TOKEN=ghp_abcdefg
```

Now we can fire up runway!

```bash
docker compose up --build -d
```

Let's explain what this all did:

1. We created a docker compose service to start runway
2. We configured our docker compose service to mount a `keys` and a `config` volume from our local disk. The `keys` volume contains the public/private key pair used for remote SSH commands on a given server with public key authentication
3. We created a new runway configuration file (under `config/config.yml`) giving runway events to listen for (`in_progress` GitHub deployments) and deployments to run when these events are triggered
4. We created a new `keys/` directory and placed our public/private keys inside of it (with the correct permisions)
5. We created a new `creds.env` file containing our `GITHUB_TOKEN` so that runway can authenticate and listen for / complete GitHub deployments

Now if runway detects an `in_progress` deployment for the `runwaylab/test-flight` repository under either the `production` or `staging` environment, it will SSH into the `remote` server and execute the `script/deploy` script with the provided GitHub REF that triggered the deployment.

> Note: Yes this example was complex and verbose. Yes this example requires some fine tuning and setup to work for your project... but that is the point, showing you what can be accomplished with runway and how you can leverage it for your own projects in a very flexible/open way!

## Contributing 🤝

See the [contributing documentation](CONTRIBUTING.md) to learn more about how you can contribute or develop runway.
