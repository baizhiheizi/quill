# frozen_string_literal: true

require "test_helper"

# Grover::BaseController gates every action behind a token check:
# `Rails.application.credentials.dig(:grover, :token) == params[:token]`.
# The credentials memoization in Rails means we need a process-wide stub
# whose lifetime matches the test run, plus per-test hooks to install and
# tear it down. We replace the whole `credentials` method on Rails.application
# rather than mucking with `@credentials`, because the latter trips up
# process-wide memoization across the two Grover test classes.
module GroverCredentialsStub
  GLOBAL_LOCK = Mutex.new

  module SavedState
    @installed = false
    @original_unbound_method = nil

    class << self
      attr_accessor :installed, :original_unbound_method
    end
  end

  def stub_grover_token
    @stub_grover_token = "configured-token-stub"
    GroverCredentialsStub::GLOBAL_LOCK.synchronize do
      unless SavedState.installed
        SavedState.original_unbound_method = Rails.application.method(:credentials).unbind
        SavedState.installed = true
      end
      token = @stub_grover_token
      stub = Object.new
      stub.define_singleton_method(:dig) do |*args|
        token if args == [ :grover, :token ]
      end
      Rails.application.define_singleton_method(:credentials) { stub }
    end
  end

  def restore_grover_token
    GroverCredentialsStub::GLOBAL_LOCK.synchronize do
      return unless SavedState.installed
      Rails.application.singleton_class.send(:define_method, :credentials, SavedState.original_unbound_method)
    end
  end

  # The Grover views reference fixture fields (`@collection.author.avatar_url`)
  # that the bare-bones collection fixture doesn't supply. We only care
  # about the controller's instance variables and the authentication
  # gate, so neutralise the template lookup.
  def skip_template_render!
    @controller.send(:instance_variable_set, :@_rendered, true)
    original_method = @controller.method(:render)
    @controller.define_singleton_method(:render) do |*args|
      next true if args.empty? && instance_variable_defined?(:@_rendered)
      original_method.call(*args)
    end
  end
end

class GroverArticlesControllerTest < ActionController::TestCase
  include GroverCredentialsStub

  tests Grover::ArticlesController

  setup do
    stub_grover_token
    @article = articles(:published_paid)
  end

  teardown do
    restore_grover_token
  end

  test "rejects requests without a token" do
    assert_raises(RuntimeError) { get :poster, params: { article_uuid: @article.uuid } }
  end

  test "rejects requests with a wrong token" do
    assert_raises(RuntimeError) { get :poster, params: { article_uuid: @article.uuid, token: "wrong" } }
  end

  test "poster assigns the article and dimensions when token matches" do
    get :poster, params: { article_uuid: @article.uuid, token: @stub_grover_token }

    assert_equal @article, @controller.instance_variable_get(:@article)
    assert_equal 640, @controller.instance_variable_get(:@width)
    assert_equal 860, @controller.instance_variable_get(:@height)
  end
end

class GroverCollectionsControllerTest < ActionController::TestCase
  include GroverCredentialsStub

  tests Grover::CollectionsController

  setup do
    stub_grover_token
    @collection = collections(:one)
    skip_template_render!
  end

  teardown do
    restore_grover_token
  end

  test "cover assigns the collection and dimensions when token matches" do
    get :cover, params: { collection_id: @collection.id, token: @stub_grover_token }

    assert_equal @collection, @controller.instance_variable_get(:@collection)
    assert_equal 640, @controller.instance_variable_get(:@width)
    assert_equal 640, @controller.instance_variable_get(:@height)
  end
end
