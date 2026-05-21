# frozen_string_literal: true

require "test_helper"

class Articles::NotifyForFirstPublishedJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::NotifyForFirstPublishedJob.perform_now(-1) }
  end

  test "perform calls notify_for_first_published on article" do
    article = articles(:published_paid)
    called = false
    article.define_singleton_method(:notify_for_first_published) { called = true }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:id] == article.id ? article : nil }) do
      Articles::NotifyForFirstPublishedJob.perform_now(article.id)
    end

    assert called
  end
end
