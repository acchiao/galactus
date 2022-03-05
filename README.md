# galactus

[![CI](https://github.com/acchiao/galactus/actions/workflows/ci.yml/badge.svg)](https://github.com/acchiao/galactus/actions/workflows/ci.yml)
[![Release](https://github.com/acchiao/galactus/actions/workflows/release.yml/badge.svg)](https://github.com/acchiao/galactus/actions/workflows/release.yml)

## Prerequisites

  * [Helm] ^3.8.0

[Helm]: https://helm.sh/

## Charts

Add the galactus repository to Helm:

```shell
helm repo add raccoon https://galactus.raccoon.team
helm repo update
helm search repo galactus
````

### Development

```sh
sail build --no-cache
sail up

docker buildx create --use
docker buildx build \
  --file Dockerfile \
  --secret id=auth,src=auth.json \
  --tag galactus \
  --load .

docker scan --file Dockerfile galactus
```
