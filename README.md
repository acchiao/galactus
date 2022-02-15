# galactus

The All-Knowing User Service Provider Aggregator.

## Usage

```sh
sail build --no-cache
sail up

DOCKER_BUILDKIT=1 docker buildx build --file Dockerfile --tag galactus --load .
```
