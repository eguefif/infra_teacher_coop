# Teacher Coop Infra

This repo contains code that manage the infrastructure of the website: www.teachercoop.org.

## Architecture

The repo [teacher_coop](https://github.com/eguefif/teacher_coop) has a Github Action that build a new image anytime there is a new commit. Eventually, it pushes a new image in dockerhu eguefif/ and send the tag to the server.

For now, migration will be run by the app service. We will use parallelism: 1 to be sure that we don't run migration at the same time.

The webhook will be used by the GHA since we cannot configure docker hub's one.

## Deploy

The infrastructure is split into two stacks that share the `traefik_public` overlay network:
- `infra.yml`: traefik, portainer and the portainer agent. Deployed from the CLI.
- `app.yml`: teacher_coop, meilisearch and the migration service.

```sh
# Once, on the manager
docker network create --driver overlay traefik_public
docker network create --driver overlay agent_network

docker stack deploy -c infra.yml infra
docker stack deploy -c app.yml teachercoop
```


## TODO
- [x] Configure DB: user and password
- [x] Configure Meilisearch
- [x] Define secret
- [x] Make traefik redirect to the app
- [x] Create a domain name
- [x] Configure let's encrypt
- [ ] Modify GHA to use the webhooks. Put the secret code in a GH secret
- [ ] Create a GH that trigger something on the server and pull new repo
    - [ ] It first should run a migration service wait for it
    - [ ] Then update current teacher_coop containers
- [ ] Need an email adapter to make it works: see mailgun.
- [x] I need to seperate portainer from the other stack. It has to run independatly
    - [x] Have traefik and portainer on one stack
    - [x] Have the rest on another stack
