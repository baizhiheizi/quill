# frozen_string_literal: true

require "test_helper"

# Pins the contract of the `UserFieldPreloads` concern (the canonical
# avatar-ActiveStorage preload chain) across every controller base that
# includes it. The chain is consumed by partials that render
# `shared/_avatar` or `admin/users/_field`; if any controller silently
# drops the concern, every row of its index action fires ~3 SELECTs
# (authorization + attachment + blob/variant) per request.
#
# The same shape is intentionally reused by `Admin::BaseController`,
# `Dashboard::BaseController`, and `Users::BaseController` so all three
# surfaces can render the same partials without one path firing extra
# queries. If the chain ever diverges between bases, audit it here.
class UserFieldPreloadsTest < ActiveSupport::TestCase
  EXPECTED_PRELOADS = [
    :authorization,
    {
      avatar_attachment: {
        blob: {
          variant_records: { image_attachment: :blob },
          preview_image_attachment: { blob: { variant_records: { image_attachment: :blob } } }
        }
      }
    }
  ].freeze

  test "Admin::BaseController exposes the canonical preload chain via user_field_preloads" do
    base = Class.new(ActionController::Base) { include UserFieldPreloads }
    assert_equal EXPECTED_PRELOADS, base.new.user_field_preloads
  end

  test "Dashboard::BaseController exposes the canonical preload chain via user_field_preloads" do
    assert_equal EXPECTED_PRELOADS, Dashboard::BaseController.new.user_field_preloads
  end

  test "Users::BaseController exposes the canonical preload chain via user_field_preloads" do
    assert_equal EXPECTED_PRELOADS, Users::BaseController.new.user_field_preloads
  end

  test "Users::BaseController no longer carries the duplicated users_user_field_preloads helper" do
    refute_includes Users::BaseController.instance_methods(false), :users_user_field_preloads,
      "Users::BaseController should reuse UserFieldPreloads#user_field_preloads; " \
      "a duplicated helper defeats the single-source-of-truth refactor."
  end
end
