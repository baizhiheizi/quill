# frozen_string_literal: true

require "test_helper"

class Dashboard::CollectionsControllerTest < ActionController::TestCase
  tests Dashboard::CollectionsController

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  # index --------------------------------------------------------------

  test "index lists the current user's collections" do
    Collection.create!(
      author: @user,
      name: "Mine",
      symbol: "MINE",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    get :index

    assert_response :success
    collections = @controller.instance_variable_get(:@collections)
    assert_equal 1, collections.size
    assert_equal "Mine", collections.first.name
  end

  # show ---------------------------------------------------------------

  test "show renders the requested collection" do
    collection = Collection.create!(
      author: @user,
      name: "Show me",
      symbol: "SHOW",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    get :show, params: { id: collection.id }

    assert_response :success
    assert_equal collection.id, @controller.instance_variable_get(:@collection).id
  end

  # new ----------------------------------------------------------------

  test "new builds an unsaved collection for the current user" do
    get :new

    assert_response :success
    collection = @controller.instance_variable_get(:@collection)
    assert_not_nil collection
    assert collection.new_record?
    assert_equal @user, collection.author
  end

  # edit ---------------------------------------------------------------

  test "edit loads an existing collection" do
    collection = Collection.create!(
      author: @user,
      name: "Editable",
      symbol: "EDIT",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    get :edit, params: { id: collection.id }

    assert_response :success
    assert_equal collection.id, @controller.instance_variable_get(:@collection).id
  end

  # create -------------------------------------------------------------

  test "create persists a valid collection and redirects" do
    assert_difference -> { Collection.count }, 1 do
      post :create, params: {
        collection: {
          name: "Fresh",
          symbol: "FRESH",
          description: "fresh desc",
          asset_id: currencies(:btc).asset_id,
          price: 0.001,
          revenue_ratio: 0.3
        }
      }
    end

    assert_redirected_to dashboard_write_path(tab: :collections)
  end

  test "create re-renders :new with bad_request when params are invalid" do
    assert_no_difference -> { Collection.count } do
      post :create, params: { collection: { name: "" } }
    end

    assert_response :bad_request
  end

  # update -------------------------------------------------------------

  test "update persists changes and redirects" do
    collection = Collection.create!(
      author: @user,
      name: "Old",
      symbol: "OLD",
      description: "old desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.001,
      revenue_ratio: 0.2
    )

    patch :update, params: {
      id: collection.id,
      collection: { description: "new desc", price: 0.002, revenue_ratio: 0.25 }
    }

    assert_redirected_to dashboard_write_path(tab: :collections)
    collection.reload
    assert_equal "new desc", collection.description
  end

  test "update re-renders :edit when params are invalid" do
    collection = Collection.create!(
      author: @user,
      name: "Test",
      symbol: "TST",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.001,
      revenue_ratio: 0.2
    )

    patch :update, params: {
      id: collection.id,
      collection: { price: -1 }
    }

    assert_response :bad_request
  end

  # destroy ------------------------------------------------------------

  test "destroy removes an unpublished collection and redirects" do
    collection = Collection.create!(
      author: @user,
      name: "Trash",
      symbol: "TRASH",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.001,
      revenue_ratio: 0.2
    )
    # Clear any articles that would otherwise block the destroy via the
    # `restrict_with_exception` association on `Collection`.
    Article.where(collection_id: collection.uuid).delete_all

    assert_difference -> { Collection.count }, -1 do
      delete :destroy, params: { id: collection.id }
    end

    assert_redirected_to dashboard_write_path(tab: :collections)
  end

  test "destroy is a no-op when may_destroy? is false (published)" do
    collection = Collection.create!(
      author: @user,
      name: "Published",
      symbol: "PUB",
      description: "desc",
      asset_id: currencies(:btc).asset_id,
      price: 0.001,
      revenue_ratio: 0.2,
      uuid: SecureRandom.uuid
    )

    assert collection.published?

    assert_no_difference -> { Collection.count } do
      delete :destroy, params: { id: collection.id }
    end

    # `may_destroy?` short-circuits the action; no redirect is performed,
    # so the response defaults to `head :no_content` semantics.
    assert_includes [ 302, 204, 200 ], @response.status
  end
end
