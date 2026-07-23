# frozen_string_literal: true

require "test_helper"

# Controller-level coverage for `Dashboard::PaymentsController#index`, which
# renders the user's payment history table (the read-side of the Write/Read
# workspace, accessed from the Finances rail). Smoke-test that the collection
# renders, respects the pagination default, and eager-loads the currency
# association consumed by the `_payment` partial.
class Dashboard::PaymentsControllerTest < ActionController::TestCase
  tests Dashboard::PaymentsController

  include CommerceHelpers
  include QuillBotStub

  setup do
    @user = users(:author)
    session[:current_session_id] = Session.create!(
      user: @user,
      uuid: SecureRandom.uuid,
      info: { "provider" => "mixin" }
    ).uuid
  end

  test "index renders successfully with no payments" do
    get :index

    assert_response :success
    payments = @controller.instance_variable_get(:@payments)
    assert payments.blank?
  end

  test "index renders payments for the current user" do
    article = articles(:published_paid)
    create_payment!(payer: @user, article: article)

    get :index

    assert_response :success
    payments = @controller.instance_variable_get(:@payments)
    assert payments.any?
    assert_equal @user.mixin_uuid, payments.first.payer_id
  end

  test "index eager-loads the currency association" do
    article = articles(:published_paid)
    create_payment!(payer: @user, article: article)

    get :index

    payments = @controller.instance_variable_get(:@payments)
    payment = payments.first
    assert payment.association(:currency).loaded?,
           "Expected currency to be eager-loaded, got lazy load"
  end

  test "index sets up pagy pagination" do
    article = articles(:published_paid)
    3.times do
      create_payment!(payer: @user, article: article)
    end

    get :index

    assert_response :success
    pagy = @controller.instance_variable_get(:@pagy)
    assert_not_nil pagy
    assert_equal 1, pagy.page
    assert_equal 3, pagy.count
  end
end
