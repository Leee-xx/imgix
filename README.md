# README

* Ruby version
2.4

* System dependencies
HTTPI

* Usage
```require 'imgix'
imgix = Imgix::PaletteRequest.new
image = 'https://assets.imgix.net/unsplash/bridge.jpg'

pp imgix.get_palette(image)

contrast_palette = imgix.get_overlay_text_color(image)
pp contrast_palette
```

See the ```examples``` directory for example scripts.