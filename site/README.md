# JellyTranslate Site

Static landing page for JellyTranslate.

## Local Preview

Open `index.html` in a browser, or run a tiny local server:

```sh
cd site
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080
```

## Netlify

The repository root contains `netlify.toml`:

```toml
[build]
  base = "site"
  publish = "."
```

When connecting the GitHub repository to Netlify, Netlify can use this config automatically.

## Download Link

The `Download on Mac` button points to the current public test version:

```text
https://github.com/jellyfishhoner/JellyTranslate/releases/download/v0.1.0-alpha/JellyTranslate-0.1.0-alpha-mac.zip
```

When publishing a new release, update:

- the download URL in `index.html`
- the `releaseVersion` constant in `index.html`
- this note

The easiest way to update those together:

```sh
../scripts/bump-version.sh 0.1.1 alpha
```

Before publishing, run:

```sh
../scripts/check-release-state.sh
```
