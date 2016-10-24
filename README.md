# Tile generator

Give it a bunch of photos and get map-like tiles back.

## Workflow

Possible inputs:

- one or many raster images: JPG or PNG, or one multi-page PDF,
- zoom levels, like `[0, -1, -2]` where 0 is base zoom level,
- unique identity, like `ABCDEF012345`.

Workflow:

- receive an HTTP request with URLs of images or PDF,
- download them,
- glue all the images together horizontally to get a very wide single
  picture,
- run through all the zoom levels, and for every level
  - extend canvas to make both width and height divisible by 256, separately.
  - cut into tiles of 256x256 size,
  - rename tiles from `tile_<n>` using tile's column and row, like `tile_<y>_<x>`.

Output:

- immediately: 201 Created, and
- collection of files, each is a tile, uploaded to AWS S3 bucket.

Current implementation uses ImageMagick, we can use GraphicsMagic instead.

## Development

Install ImageMagick:

```bash
brew install imagemagick
```

Create .env file as in env.example

Then install dependencies:

```
bundle install
```

then run the script.

or run web server:

```
heroku local
```
