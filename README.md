![Banner](docs/Banner.png)

# DropMeJPEG

MacOS Menu Bar app to automatically convert AirDrop'd `.heic` images to `.jpeg`. It's as simple as opening the app and sending yourself some images via AirDrop. This was a feature I've been wanting, so I built it myself.

> [!NOTE]  
> The app is working well on my machine, but I am still finalizing a few more things before I release it to the App Store. It will remain free and open-source.

## Why build this?

Until now, the alternative for me has been to open the `.heic` image in **Preview app** and then export it as a `.jpeg` (10+ clicks). As of a recent MacOS update, you can open the image in Finder and right-click to convert it to JPEG (4-5 clicks).

Yes, you can also disable the High-Effeiciency Image Format (HEIF) in the Camera settings. But with our option to keep or delete the original `.heic` files, you can have the best of both worlds.

## Powered by `sips`

To convert images, this app utilizes the Scriptable Image Processing System (sips) which is built-into MacOS. Specifically the `format` command.

```bash
sips --setProperty format jpeg --out filename.jpeg filename.HEIC
```

View the [`sips` MAN page](https://ss64.com/mac/sips.html).

## Changelog

| Date       | Version | Description                                |
| ---------- | ------- | ------------------------------------------ |
| 2024-11-28 | 1.1.0   | Add ability to keep original `.heic` files |
| 2024-11-28 | 1.0.0   | Initial Release (minimum viable product)   |
