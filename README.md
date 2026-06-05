# Publish FoundryVTT Package Release

Composite GitHub Action that publishes a FoundryVTT package release via the official [Package Release API](https://foundryvtt.com/article/package-release-api).

## Prerequisites

- Your release workflow must produce the package manifest (`module.json`, `system.json`, or `world.json`) and attach it to the GitHub Release as an asset, so Foundry clients can fetch it at install time. The action itself does not fetch that asset. Rather, it reads the manifest from a local path you pass as `manifest-path` (the same file your build produced), and transmits the asset URL to FoundryVTT API as `manifest-url`.
- The manifest must contain the fields Foundry requires for a release: `id`, `version`, `compatibility.minimum`, and `compatibility.verified`. `compatibility.maximum` and `changelog` (used as the default release-notes URL) are optional. This action will fails if a required field is missing.
- A repository secret named containing a Package Release API token; these start with `fvttp_` and are managed on your package's edit page at `https://foundryvtt.com/packages/<your-package-id>/edit`.

## Usage

```yaml
name: Release Foundry Package

on:
  release:
    types: [published]

env:
  release_manifest_url: https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/module.json

jobs:
  publish-to-foundry:
    runs-on: ubuntu-latest
    steps:
      # Build steps that produce module.json and attach it to the GitHub Release.
      - name: Publish FoundryVTT Package Release
        # The GitHub Release is already recorded by the time this runs; a
        # Foundry-side hiccup should not paint the run red.
        continue-on-error: true
        uses: henry-malinowski/publish-foundryvtt-package-release@v1
        with:
          foundry-token: ${{ secrets.FOUNDRY_TOKEN }}
          manifest-path: module.json
          manifest-url: ${{ env.release_manifest_url }}
          release-notes-url: ${{ github.event.release.html_url }}
```

To validate a release without publishing it, set `dry-run: true`.
Foundry will check the payload and return the same response shape as a real release, but no version is recorded.

### Separating build and publish

The example above does everything in one job. You can split build and publish instead. When split, the manifest crosses a job boundary. Bridge it with an artifact in your own workflow and hand the downloaded path to `manifest-path`.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # Build steps that produce module.json and attach it to the GitHub Release.
      - uses: actions/upload-artifact@v7
        with:
          name: foundry-manifest
          path: module.json
          if-no-files-found: error # a path typo fails here, not a job later

  publish-to-foundry:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - uses: actions/download-artifact@v8
        with:
          name: foundry-manifest
          path: manifest
      - name: Publish FoundryVTT Package Release
        continue-on-error: true
        uses: henry-malinowski/publish-foundryvtt-package-release@v1
        with:
          foundry-token: ${{ secrets.FOUNDRY_TOKEN }}
          manifest-path: manifest/module.json
          manifest-url: https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/module.json
          release-notes-url: ${{ github.event.release.html_url }}
```

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `foundry-token` | Yes | | FoundryVTT Package Release API token, including the `fvttp_` prefix. |
| `manifest-path` | Yes | | Local path to the package manifest file. The action reads and validates these bytes to build the request body. |
| `manifest-url` | Yes | | Public versioned manifest URL. Stored by Foundry and fetched by clients at install time; transmitted verbatim, never fetched by the action. |
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

Foundry rate-limits releases submitted within 60 seconds of each other. On a `429`, the action retries once, honoring the `Retry-After` header (capped at 120 seconds); if the wait would exceed that cap, or no valid `Retry-After` is returned, it gives up and surfaces the `429` instead.

## Versioning

- Pin to `@v1` for the floating major-version tag. (it tracks the latest backwards-compatible release)
- Pin to a specific commit SHA (`@<sha>`) for full reproducibility, at the cost of having to update manually for fixes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and CI conventions.

## License

Apache-2.0 — see [LICENSE](LICENSE).
