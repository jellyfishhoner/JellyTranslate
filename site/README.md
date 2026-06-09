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

The `Download on Mac` button points to the current alpha build:

```text
https://github.com/jellyfishhoner/JellyTranslate/releases/download/v0.1.0-alpha/JellyTranslate-0.1.0-alpha-mac.zip
```

When publishing a new release, update the download URL in `index.html` and this note.
