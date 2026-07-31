# frozen_string_literal: true

require "test_helper"

# `Dashboard::ListedCollectionsController` toggles a collection's visibility:
# `update` lists a published-but-hidden collection, republishes a drafted one,
# and flashes `success_updated` on success. Errors are caught and surfaced as a
# warning flash rather than a 500 so the user stays on the Write tab.
class Dashboard::ListedCollectionsControllerTest < ActionController::TestCase
  tests Dashboard::ListedCollectionsController

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "new is reachable" do
    draft = Collection.create!(
      author: @user,
      name: "Draft",
      symbol: "DRAFT",
      description: "drafted",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    get :new, params: { id: draft.id }

    assert_response :success
  end

  test "update publishes a drafted collection (assigns a uuid and lists it)" do
    draft = Collection.create!(
      author: @user,
      name: "Promote",
      symbol: "PROMO",
      description: "promote me",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )
    assert_nil draft.uuid

    patch :update, params: { id: draft.id }

    assert_redirected_to dashboard_write_path(tab: :collections)
    draft.reload
    assert_not_nil draft.uuid
    assert draft.published?
  end

  test "update lists a previously hidden collection without re-publishing" do
    collection = Collection.create!(
      author: @user,
      name: "Back",
      symbol: "BACK",
      description: "hidden then listed again",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )
    collection.publish!
    original_uuid = collection.uuid
    collection.hide!

    patch :update, params: { id: collection.id }

    assert_redirected_to dashboard_write_path(tab: :collections)
    collection.reload
    assert_equal original_uuid, collection.uuid
    assert_equal "listed", collection.state
  end

  test "update does not touch collections owned by another user" do
    other = users(:reader_one)
    foreign = Collection.create!(
      author: other,
      name: "Other",
      symbol: "OTHER",
      description: "owned by another author",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    patch :update, params: { id: foreign.id }

    assert_response :not_found
    assert_nil foreign.reload.uuid
  end

  test "update redirects unauthenticated requests to login" do
    session.delete(:current_session_id)

    draft = Collection.create!(
      author: @user,
      name: "Anon",
      symbol: "ANON",
      description: "anon draft",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )

    patch :update, params: { id: draft.id }

    assert_response :redirect
    assert_match %r{/login}, response.location
  end
end
