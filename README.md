# Scaleway Serverless Wordpress

Using [Scaleway Serverless Containers](https://www.scaleway.com/en/serverless-containers/) to run Wordpress.

## Setup

Install the [Scaleway CLI](https://github.com/scaleway/scaleway-cli#installation)

Run the setup command:

```
make deploy
```

You can then get the URL of your deployment with:

```
make url
```

## Development

Install [Docker compose](https://docs.docker.com/compose/) to test things locally, then run:

```
make dc-up
```

And go to http://localhost:8080 in your browser.
