# frozen_string_literal: true

require "test_helper"

class Articles::GenerateDefaultCoverJobTest < JobTestCase
  test "perform no-ops for missing article" do
    assert_nothing_raised { Articles::GenerateDefaultCoverJob.perform_now(-1) }
  end

  test "perform generates default cover when article has no cover" do
    article = articles(:published_paid)
    called = false
    cover = Object.new
    cover.define_singleton_method(:attached?) { false }
    article.define_singleton_method(:cover) { cover }
    article.define_singleton_method(:generate_default_cover) { called = true }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:id] == article.id ? article : nil }) do
      Articles::GenerateDefaultCoverJob.perform_now(article.id)
    end

    assert called
  end

  test "perform is a no-op when cover is already attached" do
    article = articles(:published_paid)
    cover = Object.new
    cover.define_singleton_method(:attached?) { true }
    article.define_singleton_method(:cover) { cover }
    article.define_singleton_method(:generate_default_cover) { raise "should not run" }

    stub_class_method(Article, :find_by, ->(**kwargs) { kwargs[:id] == article.id ? article : nil }) do
      assert_nothing_raised do
        Articles::GenerateDefaultCoverJob.perform_now(article.id)
      end
    end
  end
end
