# Teacher Coop Infra

This repo contains code that manage the infrastructure of the website: www.teachercoop.org.

## Architecture

The repo [teacher_coop](https://github.com/eguefif/teacher_coop) has a Github Action that build a new image anytime there is a new commit. Eventually, it pushes a new image in dockerhu eguefif/ and send the tag to the server.

On the server, there is https service that listen to port 10000. Anytime it receives a new tag, it will run a short lived service that will run the migrations (even if there is no new migration). If the migration task is successfull, it will update the current teacher_coop containners with the new image.

If there is a problem with migration, we send an email to the admin.

## Security

Only the GHA can pull the update service on the server. It signs with a private key the tag and the server decrypt the tag using the public key to be sure it is from the GHA.

The GHA connects to the server using https. Let's encrypt is configure to handle signed http connection.

## TODO
- [x] Configure DB: user and password
- [x] Configure Meilisearch
- [x] Define secret
- [x] Make traefik redirect to the app
- [x] Create a domain name
- [x] Configure let's encrypt
- [ ] Need an email adapter to make it works: see mailgun.
- [ ] Create a GH that trigger something on the server and pull new repo
    - [ ] It first should run a migration service wait for it
    - [ ] Then update current teacher_coop containers
