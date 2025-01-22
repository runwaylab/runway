# Events 🕒

Events are "things" that runway looks for which trigger deployments. This document goes over the different types of events that runway can look for and how to configure them.

All event example configurations assume that you are extending an example configuration like this one:

```yaml
projects:
  - name: project-1
    deployment:
      type: command
      location: local
      path: foo/bar/
      timeout: 5
      entrypoint: bash
      cmd: ["-c", "echo 'success'"]
    events:
      # this is the important part right here! this is the section that this page is all about
      # you can have any number of events here, just make sure they are properly indented...
      # ... and you follow the docs for the event type you are using, which you can find on this page below
      - type: example # this is what each section will document on this page!
      # ...
```

## File Event

The file event is an incredibly simple event that looks for the existence of a file in a directory. When the file is found, runway will trigger a deployment.

> This event is mostly just used for unit and acceptance testing purposes within this project

Usage:

```yaml
type: file
path: acceptance/projects/project-2/ship-it.txt # the path to the file to look for
cleanup: true # remove the file after the event (true or false)
schedule:
  interval: 3s # how often to check for the file
```

## GitHub Deployment Event

GitHub deployment events look for a specific environment that has been deployed on GitHub ([learn more about deploying environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)). This event runs on a schedule and looks for the most recent deployment in the specified environment and checks to see if it is in the `in_progress` state. If it is, it triggers a deployment event.

The most common use case for this event type, is to look for and complete branch-deploy workflows that are triggered via IssueOps in GitHub Actions. Here is a [live example](https://github.com/GrantBirki/pihole/blob/94b3df5063e4ce43d48e2244e87d157528d30935/.github/workflows/branch-deploy.yml).

By using this event type, you can tell `runway` to periodically check a given repo + environment for a deployment in progress and trigger a deployment when it finds one to complete it.

Usage:

```yaml
- type: github_deployment # github deployment event
  repo: runwaylab/test-flight # the GitHub repository to check for deployment events
  environment: production # the specific GitHub environment to check for
  deployment_filter: 1 # only look at the most recent deployment (based on the created_at field) - this field is required only for the github_deployment type event. It helps to save on API requests to GitHub. If not provided, it defaults to 1
  schedule:
    interval: 3s # intervals can be in milliseconds, seconds or minutes (ms, s, or m) - or a cron expression
    timezone: UTC # the timezone to use for the schedule (default is UTC) - ex: Europe/Berlin or America/New_York - see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
```

### Branch Deploy Features

You can optionally enable some features to the `github_deployment` event that are specific to the [`branch-deploy`](https://github.com/github/branch-deploy) workflow in GitHub Actions. These features are not enabled by default.

```yaml
- type: github_deployment
# ...
  branch_deploy:
    enabled: true # enable custom github/branch-deploy payload hydration (required for the features below)
    remove_initial_reaction: true # remove the initial reaction from the github/branch-deploy comment (only works if the original comment was made by the owner of the PAT being used to authenticate with the GitHub API)
    success_reaction: rocket # react to successful github/branch-deploy comments with a 🚀
    failure_reaction: '-1' # react to failed github/branch-deploy comments with a 👎
```
