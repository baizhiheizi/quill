# frozen_string_literal: true

# config/initializers/grover.rb
#
Grover.configure do |config|
  config.use_png_middleware = true
  config.use_jpeg_middleware = true
  config.use_pdf_middleware = false
  # Only render screenshots for explicit Grover routes (posters, covers).
  # Without this, spam scans like /articles/foo.jpg hit Grover middleware and raise errors.
  config.ignore_path = ->(path) { !path.start_with?("/grover/") }
end
