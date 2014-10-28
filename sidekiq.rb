require "octokit"
Octokit.auto_paginate = true

require "./workers/update_all"

redis_conn = proc {
  Redis.new
}
Sidekiq.configure_client do |config|
  config.redis = ConnectionPool.new(size: 4, &redis_conn)
end
Sidekiq.configure_server do |config|
  config.redis = ConnectionPool.new(size: 2, &redis_conn)
end
