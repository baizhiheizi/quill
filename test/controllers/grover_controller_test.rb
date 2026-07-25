# frozen_string_literal: true

require "test_helper"

# Grover::BaseController gates every action behind a token check:
# `Rails.application.credentials.dig(:grover, :token) == params[:token]`.
# We replace the entire `Rails.application.credentials` with a stub
# object for the duration of each test.
module GroverCredentialsStub
  def stub_grover_token
    @stub_grover_token = "configured-token-stub"
    @original_credentials = Rails.application.credentials
    token = @stub_grover_token
    stub = Object.new
    stub.define_singleton_method(:dig) do |*args|
      token if args == [ :grover, :token ]
    end
    Rails.application.instance_variable_set(:@credentials, stub)
  end

  def restore_grover_token
    Rails.application.instance_variable_set(:@credentials, @original_credentials)
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
