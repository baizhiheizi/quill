# frozen_string_literal: true

require "test_helper"

# `Dashboard::HiddenCollectionsController` is a thin toggle: `update` hides a
# listed collection owned by the current user and redirects back to the Write
# tab. The controller relies on `Collection#hide!` (AASM `hide` event from
# `:listed` to `:hidden`) and the owner-scoped `load_collection` before-action.
class Dashboard::HiddenCollectionsControllerTest < ActionController::TestCase
  tests Dashboard::HiddenCollectionsController

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid

    @collection = Collection.create!(
      author: @user,
      name: "Hideable",
      symbol: "HIDE",
      description: "ready to hide",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )
    @collection.publish!
    assert @collection.may_hide?, "fixture must be in :listed state"
  end

  test "new is reachable" do
    get :new, params: { id: @collection.id }

    assert_response :success
  end

  test "update hides a listed collection owned by the current user" do
    patch :update, params: { id: @collection.id }

    assert_redirected_to dashboard_write_path(tab: :collections)
    assert_equal "hidden", @collection.reload.state
  end

  test "update is a no-op when the collection is already hidden" do
    @collection.hide!

    assert_no_difference -> { @collection.reload.updated_at } do
      patch :update, params: { id: @collection.id }
    end

    assert_redirected_to dashboard_write_path(tab: :collections)
    assert_equal "hidden", @collection.reload.state
  end

  test "update does not affect collections owned by another user" do
    other = users(:reader_one)
    foreign = Collection.create!(
      author: other,
      name: "Foreign",
      symbol: "FOREIGN",
      description: "owned by another author",
      asset_id: currencies(:btc).asset_id,
      price: 0.0005,
      revenue_ratio: 0.2
    )
    foreign.publish!

    patch :update, params: { id: foreign.id }

    assert_response :not_found
    assert_equal "listed", foreign.reload.state
  end

  test "update redirects unauthenticated requests to login" do
    session.delete(:current_session_id)

    patch :update, params: { id: @collection.id }

    assert_response :redirect
    assert_match %r{/login}, response.location
  end
end
