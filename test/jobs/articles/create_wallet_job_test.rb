# frozen_string_literal: true

require "test_helper"

class Articles::CreateWalletJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::CreateWalletJob.perform_now(-1) }
  end

  test "perform creates wallet when article has none" do
    article = articles(:published_paid)
    called = false
    article.define_singleton_method(:wallet) { nil }
    article.define_singleton_method(:create_wallet!) { called = true }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:id] == article.id ? article : nil }) do
      Articles::CreateWalletJob.perform_now(article.id)
    end

    assert called
  end
end
