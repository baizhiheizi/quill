require "test_helper"

class ProbeSearchTest < ActionDispatch::IntegrationTest
  test "probe first /search response" do
    get "/search", params: { query: "x" }
    puts "STATUS: #{response.status}"
    puts "BODY: #{response.body[0, 400].inspect}"
  end
end
