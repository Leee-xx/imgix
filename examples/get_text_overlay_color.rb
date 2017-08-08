require 'imgix'

imgix = Imgix::PaletteRequest.new

image = 'https://assets.imgix.net/unsplash/bridge.jpg'

contrast_palette = imgix.get_overlay_text_color(image)
pp contrast_palette


