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
  end
end
