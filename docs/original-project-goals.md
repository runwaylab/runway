# Project Goals 🏆

The main **goal** of this project is to provide an easier way to setup a deployment controller for a variety of projects. Especially in situations like a homelab where you might not want to expose anything on your local network to the internet.

This project was originally created as a way to solve a specific problem in mind. *"How can I have a raspberry pi run a web app and have it automatically update when I push to a git repository or start a deployment on GitHub?"* When a deployment is triggered on GitHub via something like the [`github/branch-deploy`](https://github.com/github/branch-deploy) Action, there isn't a super easy way to connect to a raspberry pi running on your home network and deploy those changes. We can't SSH into the raspberry pi (or any other server) without exposing it to the internet. We also cannot have a webhook that GitHub can hit to trigger a deployment for the same reason. Now of course you could use a VPN, or port forward to your home server, but that is yet another thing to manage and its not something everyone really wants to do. Also, residential ISPs can be a pain to work with when it comes to port forwarding and they can change your IP address at any time.

So how do we solve this problem in a way that requires the least amount of maintenance, is secure, and super easy to use? Well, that is where `runway` comes in. `runway` is a deployment controller (favors "pull" based operations) that can be run on any server that can reach the internet. It can be configured to check for updates to a list of projects and deploy them when it finds a new commit, deployment, push to a target branch, or a new release. It can also be configured to deploy a project in a specific way (e.g. `git pull && make deploy`). `runway` can also be configured to integrate with GitHub to *complete* deployments. This means that when a deployment is triggered on GitHub, `runway` can be configured pick up that deployment, and complete it.

Let's say you have a repository called `pihole-config` that stores configuration files for your pihole server running in your homelab. You want to manage your PiHole via the git flow by making PRs and deploying those PRs on GitHub within your `pihole-config` repository. You can configure `runway` to periodically check for new deployments in that repository, and when it finds one, it can SSH into your PiHole server and deploy the changes.

In fact, that is [exactly what I do](https://github.com/GrantBirki/pihole) to follow the git flow process to update my PiHole, all without ever having to expose my PiHole to the internet or even have to SSH into it. Runway does all the work for me.

## Summary

1. Give projects a way to have more robust deployments when they live behind a firewall and you don't want to expose a webhook to the internet (e.g. a private k8s cluster or a raspberry pi running a cool web app)
2. You can give runway a list of projects and it will periodically check for updates and deploy them
3. You can tell runway *how* to deploy a project (e.g. `git pull && make deploy`)
4. runway can be run as a standalone binary or as a docker container
5. runway can be configured via a yaml file and environment variables
6. runway can integrate with GitHub to *complete* deployments
7. runway can run on both amd64 and arm64 platforms
8. runway should be "pluggable" so that you can add new event triggers and deployment methods
9. runway should be intuitive to use and easy to configure

Runway is an *event driven system*. It looks for events that should "trigger deployments" and then acts on them based on the configuration you provide. Runway is not a CI/CD system, it is a deployment controller. It is meant to be run on a server that can reach the internet and can reach your target servers or projects. It can run on the same server as your projects, or on a separate server. It is up to you how you want to configure it.
