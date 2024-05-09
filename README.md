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

- 🔍 Event driven system that looks for deployment events
- ✏️ Configurable - You define the events, how often runway should check for events, and how deployments should be executed
- 📦 Plugable - You can write new deployment strategies or deployment events to extend runway
- 🦾 ARM Support - Runway's pre-built Docker images run on both `x86_64` platforms and `ARM` platforms
- 🚀 Native [github/branch-deploy](https://github.com/github/branch-deploy) support - Runway can look for, and complete GitHub deployments
- 🐳 Fully Dockerized - Runway has [pre-built Docker images](https://github.com/runwaylab/runway/pkgs/container/runway) that make it easy to get started
- 🌱 Small Footprint - Runway is written in [crystal](https://github.com/crystal-lang/crystal) and has a tiny memory footprint. It can even run on a Raspberry Pi 4!

## Contributing 🤝

See the [contributing documentation](CONTRIBUTING.md) to learn more about how you can contribute or develop runway.
