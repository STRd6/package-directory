require "sidekiq"
require "sidekiq/web"

require './app'

Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  password == ENV["SIDEKIQ_PASSWORD"]
end

redis_conn = proc {
  Redis.new
}

Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 2, &redis_conn)
end
Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 2, &redis_conn)
end

run Rack::URLMap.new(
  '/' => Sinatra::Application,
  '/sidekiq' => Sidekiq::Web
)
