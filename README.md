# galactus

The All-Knowing User Service Provider Aggregator.

## Usage

### Helm

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

```sh
helm repo add galactus https://acchiao.github.io/galactus
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages. You can then run `helm search repo
galactus` to see the charts.

To install the galactus chart:

```sh
helm install galactus galactus/galactus
```

To uninstall the chart:

```
helm delete galactus
```

### Development

```sh
sail build --no-cache
sail up

DOCKER_BUILDKIT=1 docker buildx build --file Dockerfile --tag galactus --load .
```
