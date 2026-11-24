# frozen_string_literal: true

module ActiveStorageHelpers
  # A blob record standing in for the upload a legacy `blob://<key>/…` image
  # refers to. Nothing reads the file.
  def create_blob
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new("dot"), filename: "dot.png", content_type: "image/png")
  end

  # Every blob resolves to `url` inside the block. The render pipeline
  # measures images over HTTP, so the address has to be one nothing serves:
  # a test must not depend on the network.
  def with_blob_urls(url = "https://example.invalid/uploads/dot.png")
    original_url = ActiveStorage::Blob.instance_method(:url)
    ActiveStorage::Blob.class_eval { define_method(:url) { |**| url } }
    yield
  ensure
    ActiveStorage::Blob.class_eval { define_method(:url, original_url) }
  end
end
