# frozen_string_literal: true

require "test_helper"

class CurrenciesControllerTest < ActionController::TestCase
  tests CurrenciesController

  test "index assigns the BTC fixture via the pricable scope" do
    get :index

    assert_response :success
    currencies = @controller.instance_variable_get(:@currencies)
    assert_not_nil currencies
    assert_includes currencies, currencies(:btc)
  end

  test "index excludes currencies whose asset_id is not in Article::SUPPORTED_ASSETS" do
    unsupported = currencies(:btc)
    unsupported.update_columns(asset_id: SecureRandom.uuid, raw: unsupported.raw.merge("asset_id" => SecureRandom.uuid))

    get :index

    currencies = @controller.instance_variable_get(:@currencies)
    assert_not_includes currencies, unsupported.reload
  end
end
