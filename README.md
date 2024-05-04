<h2 align="center"><img src="assets/logo.png" alt="logo" align="center" width="200px" /></h1>

<h2 align="center">runway</h1>
<p align="center">
  A pull based deployment controller for anything
</p>

<p align="center">
  <a href="https://github.com/runwayapp/runway/actions/workflows/test.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/test.yml/badge.svg?event=push" alt="test" height="18"></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/lint.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/lint.yml/badge.svg?event=push" alt="lint"/></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/acceptance.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/acceptance.yml/badge.svg?event=push" alt="acceptance"/></a>
  <a href="https://github.com/runwayapp/runway/actions/workflows/build.yml"><img src="https://github.com/runwayapp/runway/actions/workflows/build.yml/badge.svg?event=push" alt="build"/></a>
</p>

<p align="center">
  <img src="assets/language-crystal-black.svg" alt="language crystal"/>
</p>

<hr>

## Project Goals 🏆

The main **goal** of this project is to provide an easier way to have a pull based deployment system for a variety of projects.

This project was originally created as a way to solve a specific problem in mind. *"How can I have a raspberry pi run a web app and have it automatically update when I push to a git repository or start a deployment on GitHub?"* When a deployment is triggered on GitHub via something like the [`github/branch-deploy`](https://github.com/github/branch-deploy) Action, there isn't a super easy way to connect to a raspberry pi running on your home network and deploy those changes. We can't SSH into the raspberry pi (or any other server) without exposing it to the internet. We also cannot have a webhook that GitHub can hit to trigger a deployment for the same reason. Now of course you could use a VPN, or port forward to your home server, but that is yet another thing to manage and its not something everyone really wants to do. Also, residential ISPs can be a pain to work with when it comes to port forwarding and they can change your IP address at any time.

So how do we solve this problem in a way that requires the least amount of maintenance, is secure, and super easy to use? Well, that is where `runway` comes in. `runway` is a pull based deployment controller that can be run on any server that can reach the internet. It can be configured to check for updates to a list of projects and deploy them when it finds a new commit, deployment, push to a target branch, or a new release. It can also be configured to deploy a project in a specific way (e.g. `git pull && make deploy`). `runway` can also be configured to integrate with GitHub to *complete* deployments. This means that when a deployment is triggered on GitHub, `runway` can be configured pick up that deployment, and complete it.

1. Give projects a way to have more robust deployments when they live behind a firewall and you don't want to expose a webhook to the internet (e.g. a private k8s cluster or a raspberry pi running a cool web app)
2. You can give runway a list of projects and it will periodically check for updates and deploy them
3. You can tell runway *how* to deploy a project (e.g. `git pull && make deploy`)
4. runway can be run as a standalone binary or as a docker container
5. runway can be configured via a yaml file and environment variables
6. runway can integrate with GitHub to *complete* deployments

## Contributing 🤝

See the [contributing documentation](CONTRIBUTING.md) to learn more.
