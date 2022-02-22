# galactus

[![CI](https://github.com/acchiao/galactus/actions/workflows/ci.yml/badge.svg)](https://github.com/acchiao/galactus/actions/workflows/ci.yml)
[![Release](https://github.com/acchiao/galactus/actions/workflows/release.yml/badge.svg)](https://github.com/acchiao/galactus/actions/workflows/release.yml)

The All-Knowing User Service Provider Aggregator.

## Prerequisites

- [Helm] ^3.8.0

[helm]: https://helm.sh/

## Usage

### Helm

Add the chart repository.

```sh
helm repo add galactus https://acchiao.github.io/galactus
helm repo update
```

To search the repository:

```sh
helm search repo galactus
````

To install the charts:

```sh
helm install [RELEASE_NAME] galactus/galactus
```

To upgrade the charts:

```sh
helm upgrade --install [RELEASE_NAME] galactus/galactus
```

To uninstall the charts:

```sh
helm uninstall [RELEASE_NAME]
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
