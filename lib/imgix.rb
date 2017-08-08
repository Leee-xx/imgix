module Imgix
  class PaletteRequest
    require "httpi"
    VALID_FORMATS = %w(json css)
    
    attr_accessor :request, :image_url, :format

    def validate_format
      if @format.blank? || !@format.in?(VALID_FORMATS)
        raise "Invalid palette format '#{@format}'. Valid formats are #{VALID_FORMATS.inspect}"
      end
    end

    def initialize
      @request = HTTPI::Request.new
      @format = "json"
    end

    def get_palette(image_url = nil)
      url = image_url || @image_url
      validate_format()
      @request.url = url
      @request.query = {
        palette: @format
      }
      response = HTTPI.get(@request)
      response.body
    end

    def get_overlay_text_color(image_url = nil)
      @format = "json"
      palettes = JSON.parse(get_palette(image_url))
      color_palettes = palettes["colors"].map {|palette| Palette.new(palette) }
      color_palettes += palettes["dominant_colors"].values.map {|palette| Palette.new(palette) }
      
      palette = color_palettes.max {|a, b| a.luminosity_ratio <=> b.luminosity_ratio }

      pp palette
      return_palette = palette.contrast_palette
      hex = palette.contrast_palette.values.map {|val| "%02x" % Imgix::Palette.convert_to_rgb8(val)}.join

      return palette.contrast_palette.merge({"hex" => "##{hex}"})
    end

  end

  class Palette
    attr_accessor :srgb, :rgb8, :luminosity, :luminosity_ratio, :contrast_palette, :l1, :l2, :hex
    # Luminosity ratios defined by Guideline 1.4 of WCAG 2: https://www.w3.org/TR/WCAG20/#visual-audio-contrast.
    # Formulas gotten from http://juicystudio.com/article/luminositycontrastratioalgorithm.php
    # https://gamedev.stackexchange.com/questions/81482/algorithm-to-modify-a-color-to-make-it-less-similar-than-background

    def initialize(options)
      @srgb = options.except("hex")
      @hex = options['hex']
      @rgb8 = {}
      @srgb.each do |color, val|
        @rgb8[color] = Palette.convert_to_rgb8(val)
      end
      @luminosity = calculate_luminosity(@srgb)
      @contrast_palette = get_contrast_luminosity(@luminosity)
    end

    def calculate_luminosity(rgb_hash)
      luminosity = 0.2126 * rgb_hash['red'] + 0.7152 * rgb_hash['green'] + 0.0722 * rgb_hash['blue']
    end

    # (L1 + 0.05) / (L2 + 0.05) = 10
    def get_contrast_luminosity(luminosity)
      # L1 = luminosity
      l2 = (luminosity + 0.05) / 4.5 - 0.05
      # L2 = luminosity
      l1 = (luminosity + 0.05) * 4.5 - 0.05
      if l2 > 0 && luminosity > l2
        contrast_palette = get_contrast_palette(l2)
        @l1 = luminosity
        @l2 = calculate_luminosity(contrast_palette)
      elsif l1 > 0 && luminosity < l1
        contrast_palette = get_contrast_palette(l1)
        @l1 = caclulate_luminosity(contrast_palette)
        @l2 = luminosity
      end

      @luminosity_ratio = (@l1 + 0.05) / (@l2 + 0.05)
      contrast_palette
    end

    # Try to generate random RGB values to get as close to target luminosity.
    def get_contrast_palette(lum)
      if @srgb['red'] == 0
        r = rand
        b_max = [(lum - 0.2126 * r) / 0.0722, 1].min
        b = rand(b_max)
        g = (lum - 0.0722 * b - 0.2127 * r) / 0.7152
        g = 0 if g < 0
      else
        b = rand(@srgb['blue'] / 2.0)
        g = rand(@srgb['green'] / 2.0)
        r = (lum - 0.7152 * g - 0.0722 * b) / 0.2126
        r = 0 if r < 0
      end
      return { "red" => r, "green" => g, "blue" => b }
    end

    def self.convert_to_rgb8(value)
      value ** (1 / 2.2) * 255
    end

  end
end
