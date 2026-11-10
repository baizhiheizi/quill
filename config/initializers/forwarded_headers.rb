# frozen_string_literal: true

# kamal-proxy is the only proxy in front of the app, and it is the component
# that sets `X-Forwarded-For` (appending the real client address to whatever
# the caller sent). The RFC 7239 `Forwarded` header is a *client* header:
# kamal-proxy forwards it untouched, and Rack resolves the client address by
# preferring `Forwarded` over `X-Forwarded-For`.
#
# Left at the Rack default, a caller could rotate `Forwarded: for=<random>`
# and land in a fresh rate-limit bucket on every request — `Rack::Attack`
# keys its throttles on `Rack::Request#ip`, which resolves through the same
# header priority, and `ActionDispatch::RemoteIp` reads it too. Trust only the
# header the proxy actually sets.
Rack::Request.forwarded_priority = [ :x_forwarded ]
