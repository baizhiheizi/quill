# frozen_string_literal: true

# https://github.com/rack/rack-attack/blob/6-stable/docs/example_configuration.md
class Rack::Attack
  ### Configure Cache ###
  #
  # Rack::Attack throttles call `cache.increment` on every matching request,
  # so the store must be shared across all serving processes. We reuse
  # `Rails.cache` (Solid Cache, DB-backed — see config/environments/*.rb) for
  # that. Solid Cache implements `#increment` via a read-modify-write lock,
  # which is consistent (not a Redis-style atomic INCR) but correct for our
  # single-process Puma config.
  #
  # NOTE: if the app is ever scaled to multi-worker forking (`WEB_CONCURRENCY`
  # > 1), keep this on a shared store — a per-process `MemoryStore` would
  # multiply every limit below by the worker count.
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP (60rpm). The catch-all that protects every
  # unmetered route and absorbs scrapers before they hit the app.
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle("req/ip", limit: 600, period: 5.minutes, &:ip) if Rails.env.production?

  ### Prevent Brute-Force Login Attacks ###

  # Throttle POST requests to /admin/login by IP address. Admin login is the
  # most sensitive credential surface and is reachable unauthenticated.
  throttle("logins/admin/ip", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/admin/login" && req.post?
  end

  # Throttle OAuth callback hits by IP. The callback (`/auth/:provider/callback`)
  # is the account-takeover / brute-force surface and is also unauthenticated.
  throttle("oauth/callback/ip", limit: 10, period: 1.minute) do |req|
    req.ip if %r{\A/auth/[^/]+/callback\z}.match?(req.path)
  end

  ### Throttle authenticated privileged writes ###
  #
  # These are keyed on the signed-in user where possible, falling back to the
  # request IP so unauthenticated or session-less bursts are still caught. The
  # session key mirrors `ApplicationController#current_session` — see
  # `session[:current_session_id]`.

  # API requests keyed by access token (fallback IP). `HTTP_X_ACCESS_TOKEN`
  # identifies the API caller; without it the request is anonymous and the IP
  # counter applies.
  throttle("api/token", limit: 300, period: 5.minutes) do |req|
    if req.path.start_with?("/api/")
      req.env["HTTP_X_ACCESS_TOKEN"].presence || "ip:#{req.ip}"
    end
  end

  # Comment creation keyed by user (fallback IP).
  throttle("comments/user", limit: 30, period: 1.minute) do |req|
    if req.path == "/comments" && req.post?
      req.env["rack.session"]["current_session_id"].presence || "ip:#{req.ip}"
    end
  end

  # Votes (up/down on articles) keyed by user (fallback IP).
  throttle("votes/user", limit: 200, period: 1.minute) do |req|
    if req.patch? && req.path.match?(%r{\A/(up|down)voted_articles/})
      req.env["rack.session"]["current_session_id"].presence || "ip:#{req.ip}"
    end
  end

  # Subscribe / block writes keyed by user (fallback IP).
  throttle("subscribe/user", limit: 60, period: 1.minute) do |req|
    if req.path.match?(%r{\A/(subscribe_|block_)}) && %w[POST PATCH DELETE].include?(req.request_method)
      req.env["rack.session"]["current_session_id"].presence || "ip:#{req.ip}"
    end
  end

  # Pre-order creation keyed by user (fallback IP). Pre-orders kick off payment
  # flows; an unbounded burst fills the table and pings the Mixin/MixPay APIs.
  throttle("pre_orders/user", limit: 10, period: 1.minute) do |req|
    if req.path == "/pre_orders" && req.post?
      req.env["rack.session"]["current_session_id"].presence || "ip:#{req.ip}"
    end
  end

  # Access-token minting keyed by user (fallback IP). Tokens are long-lived
  # credentials; cap how fast a single account can mint them.
  throttle("access_tokens/user", limit: 5, period: 1.hour) do |req|
    if req.path == "/dashboard/access_tokens" && req.post?
      req.env["rack.session"]["current_session_id"].presence || "ip:#{req.ip}"
    end
  end

  # Search is unauthenticated and runs `ILIKE %query%`; cap the burst rate.
  throttle("search/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/search" && req.get?
  end

  ### Custom Throttle Response ###

  # Emit a `Retry-After` header, log the throttle event for forensics, and
  # return JSON for API paths (plain text otherwise). Default Rack::Attack
  # already returns 429; this makes it actionable for clients and operators.
  Rack::Attack.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"] || {}
    now = match_data[:epoch_time] || Time.now.to_i
    period = match_data[:period] || 60
    retry_after = period - (now % period)

    Rails.logger.warn(
      "[Rack::Attack] throttled " \
        "name=#{req.env["rack.attack.matched"]} " \
        "count=#{match_data[:count]} " \
        "period=#{period}s " \
        "retry_after=#{retry_after}s " \
        "ip=#{req.ip} " \
        "ua=#{req.user_agent.inspect} " \
        "path=#{req.path}"
    )

    if req.path.start_with?("/api/")
      body = { error: "rate_limited", retry_after: retry_after }.to_json
      [ 429, { "Content-Type" => "application/json; charset=utf-8", "Retry-After" => retry_after.to_s }, [ body ] ]
    else
      [ 429, { "Content-Type" => "text/plain; charset=utf-8", "Retry-After" => retry_after.to_s }, [ "Retry later\n" ] ]
    end
  end
end
