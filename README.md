# Teacher Coop Infra

This repo contains the code that manages the infrastructure of the website: www.teachercoop.org.

## TODO
- [ ] Need an email adapter to make it work: see Mailgun.
- [ ] Infra stack should be run in its own user.
- [ ] Handle document storage across multiple nodes.
- [ ] Handle Meilisearch storage.
- [ ] Check if the migration system works and if we need to modify the stack configuration.
- [ ] Add monitoring Traefik: I want to know how many connections, what kind of connections and check if I need to avoid bot etc...

## Architecture

### Stack Overview

Here are all the programs we use to handle the infrastructure:
- Docker Swarm: container orchestrator configured via docker compose files: `infra.yml` and `app.yml`.
- Portainer: UI that hides Docker complexity and facilitates supervising/configuring stacks and services.
- GitHub: repository server and actions to build new container images and trigger deploys.
- Traefik: reverse proxy, it's the entry point of our infrastructure. It terminates SSL connections, handles certificates and routes traffic.
- Docker Hub: hosts our images.
- Postgres: database, for now it's hosted on the same machine as the infra stack.

Our containers and Docker services configurations are defined in two docker compose files that we call `stacks`:
- `infra.yml`: defines `traefik` and `portainer`
- `app.yml`: defines `teacher_coop` and `meilisearch`


#### The two stacks rationale

The `infra` stack is run manually the first time we set up the infrastructure, see the [First infra deploy documentation](#first-infra-deploy).
The rationale behind separating into two stacks is that the `infra` stack should always be available. `portainer` is our orchestrator UI and needs to
be able to add new services. It needs to access the `manager node` Docker service and perform actions on it. If it were in the same stack, any time we shut down the stack for whatever reason, we would not
be able to access Portainer and check states. It's a way to easily expand without losing the supervising service. When the `infra` stack is deployed, we can work as we want on the `app` stack
without losing `portainer`.


### Certificate

`traefik` handles SSL for us, see the private documentation to know what secrets it needs and where the `acme` file is defined.

It redirects traffic to the correct swarm service using the following URLs:
- `traefik.teachercoop.org/dashboard/` to direct to the Traefik dashboard.
- `portainer.teachercoop.org` to direct to Portainer.
- `www.teachercoop.org` or `teachercoop.org` to direct to the website app.

Note that the dashboard is protected by the `basicauth` middleware. See the private documentation to know how to configure user/password.

### First infra deploy

Even though the infra uses docker compose files and Portainer to automate a lot of actions, it still needs some manual actions at first deployment:

- [ ] Set up Postgres: see private documentation for setup.
- [ ] Define Docker secrets: see private documentation.
- [ ] Create overlay networks.
- [ ] Pull the GitHub repo and manually start the stack based on `infra.yml`.

The infrastructure is split into two stacks that share the `traefik_public` overlay network:
- `infra.yml`: traefik, portainer and the portainer agent. Deployed from the CLI.
- `app.yml`: teacher_coop and meilisearch.

Here are the commands to run to create the overlay networks and deploy `infra.yml`.
```sh
# Once, on the manager
docker network create --driver overlay traefik_public
docker network create --driver overlay agent_network

docker stack deploy -c infra.yml infra
```

The rest can be done through Portainer.

### The CD flow and automatic deploy

For this to work, it requires the following configuration:
- Create a `portainer webhook` for the `teacher_coop` service.
- Define a GH secret with the correct `hook sha secret` provided by the last step.
- The `app` stack should be up and running.

When a programmer merges a branch into the main branch of the [teacher_coop](https://github.com/eguefif/teacher_coop) repo, the `build.yml` GitHub action is executed.

This GH action builds two images, `latest` and `github.sha`, and pushes them to Docker Hub. The last step is a curl POST to the Portainer webhook responsible for triggering the deployment.
The GH action adds a query parameter with the `github.sha` tag. This tag is put in the environment and used to update the `app.yml` docker compose file and the `teacher_coop` app.

### Migration

For now, we handle migrations in a basic way. Any time we update the `teacher_coop` service, we run the migrations. Since we ask `swarm` to only deploy one container at a time, and because `ecto` locks Postgres, we don't run into migration race conditions. This is not ideal but it will do for now.

### GitHub

The repo [teacher_coop](https://github.com/eguefif/teacher_coop) has a GitHub Action named `build.yml` that builds two images and pushes them to Docker Hub.

The image tags are:
- latest
- github.sha

It also sends an HTTP POST request to the Portainer webhook to trigger deployment.
