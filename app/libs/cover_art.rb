# frozen_string_literal: true

# Deterministic decorative cover art for article cards (CSS + SVG, no PNG).
module CoverArt
  Shape = Data.define(:kind, :cx, :cy, :rx, :ry, :r, :opacity, :stroke_width, :hue_offset, :rotation)
  Art = Data.define(:background, :shapes, :base_hue)

  KINDS = %i[circle ring ellipse blob diamond].freeze

  module_function

  def for(seed)
    base_hue = ColorFromSeed.hue(seed)
    Art.new(
      background: background_css(seed, base_hue:),
      shapes: shapes_for(seed, base_hue:),
      base_hue:
    )
  end

  def background_css(seed, base_hue:)
    h2 = (base_hue + 55) % 360
    h3 = (base_hue + 130) % 360
    h4 = (base_hue + 200) % 360
    angle = 120 + (ColorFromSeed.fnv1a_hash("#{seed}-angle") % 120)
    spot_x = 12 + (ColorFromSeed.fnv1a_hash("#{seed}-spot-x") % 76)
    spot_y = 8 + (ColorFromSeed.fnv1a_hash("#{seed}-spot-y") % 84)

    <<~CSS.squish
      radial-gradient(circle at #{spot_x}% #{spot_y}%, hsla(#{h2}, 85%, 68%, 0.5) 0%, transparent 55%),
      radial-gradient(circle at #{100 - spot_x}% #{100 - spot_y}%, hsla(#{h3}, 80%, 62%, 0.38) 0%, transparent 50%),
      linear-gradient(#{angle}deg, hsl(#{base_hue}, 75%, 54%) 0%, hsl(#{h2}, 70%, 44%) 38%, hsl(#{h3}, 66%, 34%) 72%, hsl(#{h4}, 62%, 22%) 100%)
    CSS
  end

  def shapes_for(seed, base_hue:)
    count = 3 + (ColorFromSeed.fnv1a_hash("#{seed}-shape-count") % 3)

    (0...count).map do |index|
      kind = KINDS[ColorFromSeed.fnv1a_hash("#{seed}-kind-#{index}") % KINDS.length]
      cx = 8 + (ColorFromSeed.fnv1a_hash("#{seed}-cx-#{index}") % 84)
      cy = 6 + (ColorFromSeed.fnv1a_hash("#{seed}-cy-#{index}") % 88)
      size = 14 + (ColorFromSeed.fnv1a_hash("#{seed}-size-#{index}") % 28)
      opacity = 0.12 + (ColorFromSeed.fnv1a_hash("#{seed}-opacity-#{index}") % 28) / 100.0
      hue_offset = (ColorFromSeed.fnv1a_hash("#{seed}-hue-#{index}") % 120) - 30
      rotation = (ColorFromSeed.fnv1a_hash("#{seed}-rot-#{index}") % 120) - 60

      case kind
      when :circle
        Shape.new(kind:, cx:, cy:, rx: 0, ry: 0, r: size, opacity:, stroke_width: 0, hue_offset:, rotation: 0)
      when :ring
        Shape.new(kind:, cx:, cy:, rx: 0, ry: 0, r: size, opacity:, stroke_width: 1.5, hue_offset:, rotation: 0)
      when :ellipse
        Shape.new(kind:, cx:, cy:, rx: size, ry: (size * 0.62).round, r: 0, opacity:, stroke_width: 0, hue_offset:, rotation:)
      when :blob
        Shape.new(kind:, cx:, cy:, rx: (size * 1.1).round, ry: size, r: 0, opacity: opacity * 0.85, stroke_width: 0, hue_offset:, rotation:)
      when :diamond
        Shape.new(kind:, cx:, cy:, rx: size, ry: size, r: 0, opacity:, stroke_width: 1, hue_offset:, rotation: rotation + 45)
      end
    end
  end

  def shape_fill(shape, base_hue:)
    hue = (base_hue + shape.hue_offset) % 360
    "hsla(#{hue}, 78%, 72%, #{shape.opacity.round(2)})"
  end

  def shape_stroke(shape, base_hue:)
    hue = (base_hue + shape.hue_offset + 20) % 360
    "hsla(#{hue}, 70%, 82%, #{[ shape.opacity + 0.15, 0.55 ].min.round(2)})"
  end
end
