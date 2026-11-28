# frozen_string_literal: true

require "test_helper"

# End-to-end guard for the dashboard collections infinite-scroll pagination.
#
# The controller test proves the index renders the infinite-scroll trio and
# that a `turbo_stream` request returns the appended rows. This test walks
# the exact path the browser takes: it reads the "Load More" href out of the
# rendered pagination footer and fetches it with the turbo-stream Accept
# header the Stimulus controller sends.
class DashboardCollectionsPaginationTest < IntegrationTestCase
  TURBO_STREAM_ACCEPT = "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"

  test "the collections index loads the next page over the turbo stream" do
    user = users(:author)
    sign_in(user)

    # One collection more than a page holds, so a second page exists.
    collections = create_collections(user, Pagy::DEFAULT[:limit] + 1)

    get dashboard_collections_path
    assert_response :success

    # The pagination footer is the only way to reach the overflow row.
    href = @response.body[%r{<a class="hidden" href="([^"]+)">Load More</a>}, 1]
    assert_not_nil href, "expected a next-page link in the pagination footer"

    get href, headers: { "Accept" => TURBO_STREAM_ACCEPT }
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type

    # The next page appends its rows to the list container and re-renders the
    # pagination footer.
    assert_includes @response.body, 'action="append"'
    assert_includes @response.body, 'target="my_collections_list"'
    assert_includes @response.body, 'action="update"'
    assert_includes @response.body, 'target="my_collections_pagination"'

    # The overflow row is appended and no first-page row is repeated.
    assert_includes @response.body, collections.first.name
    refute_includes @response.body, collections.last.name
  end

  private

  # Creates `count` collections for `user` with distinct, zero-padded names
  # and strictly increasing `updated_at` values, so the page-1/page-2 split
  # is deterministic under `order(updated_at: :desc, id: :desc)`: the last
  # created collection heads page 1 and the first created one overflows onto
  # page 2.
  def create_collections(user, count)
    base = Time.current - count.minutes

    (0...count).map do |i|
      Collection.create!(
        author: user,
        name: format("Collection %02d", i),
        symbol: format("COLL%02d", i),
        description: "collection #{i}",
        asset_id: currencies(:btc).asset_id,
        price: 0.0005,
        revenue_ratio: 0.2,
        updated_at: base + i.minutes
      )
    end
  end
end
