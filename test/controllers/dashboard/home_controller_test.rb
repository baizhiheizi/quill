# frozen_string_literal: true

require "test_helper"

# `Dashboard::HomeController#index` composes the new dashboard Overview
# (specs/005-dashboard-ux-redesign) instead of redirecting into "My Reading" —
# verify it renders (not redirects) and shows role-appropriate content for a
# zero-activity user, a reader-only user, and an author.
class Dashboard::HomeControllerTest < ActionController::TestCase
  tests Dashboard::HomeController

  def sign_in_as(user)
    test_session = sign_in(user)
    @request.session[:current_session_id] = test_session.uuid
  end

  test "index renders (does not redirect) for a zero-activity user" do
    user = users(:reader_two)
    sign_in_as(user)

    get :index

    assert_response :success
    refute @controller.instance_variable_get(:@is_author)
    assert_select "*", text: /#{Regexp.escape(I18n.t('overview_no_bought_articles'))}/
  end

  test "index renders reader-relevant content for a reader-only user" do
    reader = users(:reader_two)
    article = articles(:published_paid)
    with_quill_bot_stub do
      create_buy_order!(article: article, buyer: reader)
    end
    sign_in_as(reader)

    get :index

    assert_response :success
    refute @controller.instance_variable_get(:@is_author)
    recent_reads = @controller.instance_variable_get(:@recent_reads)
    assert_includes recent_reads, article
  end

  test "index renders author-relevant content for an author" do
    author = users(:author)
    User.reset_counters(author.id, :articles)
    sign_in_as(author)

    get :index

    assert_response :success
    assert @controller.instance_variable_get(:@is_author)
    recent_articles = @controller.instance_variable_get(:@recent_articles)
    assert recent_articles.any?
    assert_select "*", text: /#{Regexp.escape(I18n.t('recently_published'))}/
  end
end
