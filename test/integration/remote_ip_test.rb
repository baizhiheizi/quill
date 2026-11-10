# frozen_string_literal: true

require "test_helper"

# A client-supplied Client-Ip header that disagrees with X-Forwarded-For used to
# raise ActionDispatch::RemoteIp::IpSpoofAttackError and 500 the request (#2243).
# With the spoofing check disabled, the request must complete and remote_ip must
# keep coming from the proxy-set X-Forwarded-For chain.
class RemoteIpIntegrationTest < ActionDispatch::IntegrationTest
  test "conflicting Client-Ip and X-Forwarded-For does not raise" do
    get hot_tags_path, headers: {
      "Turbo-Frame" => "hot_tags",
      "Client-Ip" => "203.0.113.9",
      "X-Forwarded-For" => "198.51.100.7"
    }

    assert_response :success
    assert_equal "198.51.100.7", request.remote_ip
  end

  # `Forwarded` (RFC 7239) is a client header that kamal-proxy passes through
  # untouched. Rack prefers it over `X-Forwarded-For`, so honouring it would
  # let a caller pick their own client address — and, because `Rack::Attack`
  # keys its throttles on that address, rotate their rate-limit bucket.
  test "Forwarded does not override the proxy-set X-Forwarded-For" do
    get hot_tags_path, headers: {
      "Turbo-Frame" => "hot_tags",
      "Forwarded" => "for=203.0.113.9",
      "X-Forwarded-For" => "198.51.100.7"
    }

    assert_response :success
    assert_equal "198.51.100.7", request.remote_ip
  end
end
