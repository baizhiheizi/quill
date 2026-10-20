# frozen_string_literal: true

require "test_helper"
require "yaml"

# The test environment overrides `supported_assets` with
# `config/settings/test.yml`. When that list was narrower than the
# production one, every non-BTC pricing path was unreachable from the suite
# — which is how the article editor ended up saving every article in BTC
# regardless of the author's choice.
class SupportedAssetsTest < ActiveSupport::TestCase
  test "the test settings cover every production asset" do
    production = supported_assets_in(Rails.root.join("config/settings.yml"))
    test = supported_assets_in(Rails.root.join("config/settings/test.yml"))

    assert_equal production.sort, test.sort,
                 "config/settings/test.yml must list every asset from config/settings.yml"
  end

  test "every supported asset has a currency fixture" do
    fixture_asset_ids = Currency.pluck(:asset_id)

    Article::SUPPORTED_ASSETS.each do |asset_id|
      assert_includes fixture_asset_ids, asset_id,
                      "add a currency fixture for #{asset_id} so its pricing path can be tested"
    end
  end

  private

  def supported_assets_in(path)
    YAML.safe_load_file(path).fetch("supported_assets")
  end
end
