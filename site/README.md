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

The `Download alpha` button points to GitHub Releases:

```text
https://github.com/jellyfishhoner/JellyTranslate/releases
```

Create a GitHub Release with a zipped `.app` or later a notarized `.dmg`, and the site will already point users to the right place.

