require 'imgix'

imgix = Imgix::PaletteRequest.new
image = 'https://assets.imgix.net/unsplash/bridge.jpg'

pp imgix.get_palette(image)

