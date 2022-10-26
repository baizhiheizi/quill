# frozen_string_literal: true

# config/initializers/grover.rb
#
Grover.configure do |config|
  config.use_png_middleware = true
  config.use_jpeg_middleware = true
  config.use_pdf_middleware = false
end
