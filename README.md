# Publish FoundryVTT Package

Composite GitHub Action that publishes a FoundryVTT package release via the official [Package Release API](https://foundryvtt.com/article/package-release-api).

## Prerequisites

- Your release workflow must produce a GitHub Release with the package manifest (`module.json`, `system.json`, or `world.json`) attached as a release asset, so Foundry can fetch it from a stable URL.
- A repository secret named `FOUNDRY_TOKEN` containing a Package Release API token; these start with `fvttp_` and are managed on your package's edit page at `https://foundryvtt.com/packages/<your-package-id>/edit`.

## Usage

```yaml
name: Release Foundry Package

on:
  release:
    types: [published]

env:
  release_manifest_url: https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/module.json

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # Build steps that attach a manifest to GitHub's Release.

  publish-to-foundry:
    runs-on: ubuntu-latest
    needs: build
    # workflow doesn't "Fail" on a Foundry-side hiccup; package Release is already done
    continue-on-error: true
    steps:
      - name: Publish FoundryVTT Package
        uses: henry-malinowski/publish-foundryvtt-package@v1
        with:
          foundry-token: ${{ secrets.FOUNDRY_TOKEN }}
          manifest-url: ${{ env.release_manifest_url }}
          release-notes-url: ${{ github.event.release.html_url }}
```

To validate a release without publishing it, set `dry-run: true`.
Foundry will check the payload and return the same response shape as a real release, but no version is recorded.

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `foundry-token` | Yes | | FoundryVTT Package Release API token, including the `fvttp_` prefix. |
| `manifest-url` | Yes | | URL to the versioned package manifest for this release. |
| `release-version` | No | Manifest `.version` | Version to publish. |
| `release-notes-url` | No | Manifest `.changelog` | Release notes URL. |
| `dry-run` | No | `false` | Set to `true` to validate without publishing. Accepts `true`, `false`, or empty (case-insensitive). |

## Outputs

| Output | Description |
| --- | --- |
| `response-code` | HTTP response code returned by Foundry. |
| `response-json` | Response body returned by Foundry. |

Both outputs are populated whenever Foundry returns any HTTP response, including `429` and other errors.
On transport failures where curl cannot reach Foundry, `response-code` may be `000` and `response-json` may be empty.
The action exits successfully only when Foundry returns HTTP `200`.

## Versioning

- Pin to `@v1` for the floating major-version tag. (it tracks the latest backwards-compatible release)
- Pin to a specific commit SHA (`@<sha>`) for full reproducibility, at the cost of having to update manually for fixes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and CI conventions.

## License

Apache-2.0 — see [LICENSE](LICENSE).
