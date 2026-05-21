# frozen_string_literal: true

require "test_helper"

class Articles::GeneratePosterJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::GeneratePosterJob.perform_now(-1) }
  end

  test "perform generates poster when none attached" do
    article = articles(:published_paid)
    called = false
    poster = Object.new
    poster.define_singleton_method(:attached?) { false }
    article.define_singleton_method(:poster) { poster }
    article.define_singleton_method(:generate_poster) { called = true }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:id] == article.id ? article : nil }) do
      Articles::GeneratePosterJob.perform_now(article.id)
    end

    assert called
  end
end
