## Intro

Proof-of-concept app built using SvelteKit and Directus 

This is a canny.io clone that allows users to submit and vote for feedbacks (or feature requests) for different companies to improve their products.

To see the demo: https://staging.broomninja.xyz

## Tech stack

- caddy for reverse proxy, ssl termination
- sveltekit + tailwind/preline - frontend and CSS
- zod for client and server side form validation, DOMPurify for XSS sanitisation
- growthbook for feature flags
- loki + grafana + promethus for monitoring [TO BE ADDED]
- directus + REDIS for auth, REST/GRAPHQL API, DB cache
- Postgres + Adminer - SQL
- SOPS + age for secrets

## Prerequisites

To run the following in any environments, docker and docker compose (v2 or above) must be installed.

In addition, [SOPS](https://github.com/mozilla/sops) and [age](https://github.com/FiloSottile/age) will have to be installed to decrypt secrets in the two .env files.

There are two ways to run the app. You can either run the entire app with a single docker-compose (see Manual Deploy) or run more "dev friendly" version which runs the backend services only with docker compose and then run the frontend with npm (see Develop).

## Develop

To run it locally for development, first start the backend docker containers as below.

A sql dump will be restored to postgres the first time you start the datastore container, this
dump also contains sample data for development and testing purposes.

```bash
# setup the private key for decryption
export SOPS_AGE_KEY_FILE=~/.sops/key.txt 
bash scripts/decrypt_env.sh .enc.env
# modify both .env files for local dev as necessary
# make sure COMPOSE_PROFILES=local is set in <project_root>/.env when running sveltekit wihtout docker
vi .env
# start up the backend containers
docker compose up -d --build
cd webapp
bash scripts/decrypt_env.sh .enc.env
# modify .env for local dev
vi .env
npm install
npm run dev
```

Now visit http://localhost:5173

To reset the directus admin password, run:

```bash
docker exec directus npx directus users passwd --email admin@test.com --password newpasswordhere

```

You can now login to directus as admin via http://localhost:8055

### Restore database dump

If you need to restore the database dump again after the initial start, do the following:

```bash
# cd to root directory of project
cd <project_root>
docker compose down
# Warning: all new data added after the initial restore will be lost and replaced by 
#          a fresh copy of the dump during postgres initialization
sudo rm -rf backend/data/database
docker compose up -d --build
```

## Manual Deploy

You will need a domain name and appropriate DNS records for caddy to work properly if you
are deploying it manually on a server

```bash
# setup the private key for decryption
export SOPS_AGE_KEY_FILE=~/.sops/key.txt 
bash scripts/decrypt_env.sh .enc.env
bash scripts/decrypt_env.sh webapp/.enc.env
# modify both .env files as necessary
# make sure COMPOSE_PROFILES=all is set in <project_root>/.env
docker compose up -d --build
```

### Admin access

To access directus admin, visit https://admin.broomninja.xyz/ (or https://admin.yourserver.com)

## SOPS and age

### Encrypt

We only need the public key for encryption, so we can pass in either SOPS_AGE_RECIPIENTS (which 
is a public key string eg. age1068.....)  or SOPS_AGE_KEY_FILE (which contains both public 
key and private key) as environment variables.

```bash
# .enc.env file will be generated
SOPS_AGE_RECIPIENTS=age1068XXXXX bash ./scripts/encrypt_env.sh .env
# OR
SOPS_AGE_KEY_FILE=~/.sops/key.txt bash ./scripts/encrypt_env.sh .env
```

### Decrypt

Private key is required for decryption.

```bash
# .env file will be generated
SOPS_AGE_KEY_FILE=~/.sops/key.txt bash ./scripts/decrypt_env.sh .enc.env
```