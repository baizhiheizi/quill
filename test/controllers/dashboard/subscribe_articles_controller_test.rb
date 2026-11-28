# frozen_string_literal: true

require "test_helper"

# `Dashboard::SubscribeArticlesController#index` renders the partial at
# `app/views/dashboard/subscribe_articles/_article.html.erb`, which walks
# `article.author.avatar_image_thumb` via `shared/avatar` with `thumb: true`.
# Before this PR the controller eager-loaded only `:author` (the User row),
# so each row fired ~5 extra SELECTs for the ActiveStorage avatar chain
# (authorization + avatar_attachment + blob + variant_records +
# image_attachment.blob). The regression-guard below asserts the index
# action completes in a small bounded number of SELECTs even when the user
# is subscribed to comments on many articles.
class Dashboard::SubscribeArticlesControllerTest < ActionController::TestCase
  tests Dashboard::SubscribeArticlesController

  # 1 pagy count + 1 articles SELECT + 1 authors SELECT + 4-5 ActiveStorage
  # SELECTs (auth + attachment + blob + variant_records + image_attachment
  # blob) for the union of all preloaded rows. Comfortably under 20 even
  # with all 5 fixture articles preloaded.
  SELECT_BUDGET = 20

  setup do
    @reader = users(:reader_one)
    sign_in_as(@reader)
  end

  test "index renders without triggering per-row avatar SELECT fan-out" do
    seed_subscriptions!

    select_count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      next if payload[:name] == "SCHEMA"

      select_count += 1
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get :index
    end

    assert_response :success
    assert_operator select_count, :<=, SELECT_BUDGET,
      "Expected index to fire ≤#{SELECT_BUDGET} SELECTs, got #{select_count}. " \
      "Likely cause: avatar chain (authorization + ActiveStorage) regressed."
  end

  test "index sets preloaded_commenting_subscribe_article_ids" do
    seed_subscriptions!

    get :index

    assert_response :success
    preloaded = @controller.instance_variable_get(:@preloaded_commenting_subscribe_article_ids)
    assert_instance_of Set, preloaded
    assert_equal @reader.commenting_subscribe_articles.count, preloaded.size
    assert_not_includes preloaded, articles(:draft).id,
      "the set must hold every commenting-subscribed article, so it can also answer the no case"
  end

  # The button state the partial renders comes from the primed set rather
  # than from a live per-row check, so pin the rendered result: every row of
  # this list is an article the viewer commenting-subscribed to, so each
  # renders the Unsubscribe link.
  test "index renders the subscribe button state from the primed set" do
    seed_subscriptions!
    article = @reader.commenting_subscribe_articles.first

    get :index

    assert_response :success
    assert_select "a[href=?]", new_subscribe_article_path(uuid: article.uuid),
      message: "expected the row to render the Unsubscribe link from the primed set"
  end

  private

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end

  # Subscribe `@reader` to all published fixture articles so the index
  # renders multiple rows. Each subscription creates one `Action` row
  # (`has_many :commenting_subscribe_article_actions`); without the
  # avatar chain eager-load, rendering each row's `shared/_avatar` partial
  # would fire ~5 SELECTs.
  def seed_subscriptions!
    Article.only_published.find_each do |article|
      next if @reader.commenting_subscribe_articles.exists?(article.id)

      @reader.create_action(:commenting_subscribe, target: article)
    end
  end
end
