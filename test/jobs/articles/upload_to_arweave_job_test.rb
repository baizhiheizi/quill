# frozen_string_literal: true

require "test_helper"

class Articles::UploadToArweaveJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::UploadToArweaveJob.perform_now(-1) }
  end

  test "perform calls upload_to_arweave! on article" do
    article = articles(:published_paid)
    called = false
    article.define_singleton_method(:upload_to_arweave!) { called = true }

    stub_class_method(Article, :find, ->(id) { id == article.id ? article : raise(ActiveRecord::RecordNotFound) }) do
      Articles::UploadToArweaveJob.perform_now(article.id)
    end

    assert called
  end
end
