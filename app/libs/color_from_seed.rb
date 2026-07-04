# frozen_string_literal: true

# Deterministic color helpers — mirrors `app/javascript/utils/avatar.js` (FNV-1a → hue).
module ColorFromSeed
  module_function

  def fnv1a_hash(str)
    hash = 2_166_136_261
    String(str).each_byte do |byte|
      hash ^= byte
      hash = (hash * 16_777_619) & 0xffffffff
    end
    hash
  end

  def hue(seed)
    fnv1a_hash(seed) % 360
  end

  def hsl(seed, saturation: 65, lightness: 45)
    "hsl(#{hue(seed)}, #{saturation}%, #{lightness}%)"
  end

  def gradient_css(seed)
    base = hue(seed)
    "linear-gradient(135deg, hsl(#{base}, 65%, 45%), hsl(#{(base + 40) % 360}, 55%, 35%))"
  end
end
