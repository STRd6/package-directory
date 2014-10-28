require "./workers/update_all"

require 'pry' if ENV["RACK_ENV"] == "development"
require 'sinatra'

require "rack/cors"

use Rack::Cors do |config|
  config.allow do |allow|
    allow.origins '*'
    allow.resource '*',
      :headers => :any
  end
end

def lookup(name, ref="master")
  Sidekiq.redis do |redis|
    if url = redis.get("distri/#{name}:#{ref}")
      redirect "#{url}?#{request.query_string}", 302
    else
      404
    end
  end
end

get '/hi' do
  "Hello World!"
end

# TODO: Package index
get '/packages.json' do
  418
end

get '/packages/:name.json' do
  lookup(params[:name])
end

# Redirect to the S3 Bucket containing the package json
# We transparently pass along the query string because S3's
# cross origin resource sharing is shitty and doesn't properly
# vary the accept origin header.
# This way domains can add ?#{document.domain} and work around that
get '/packages/:name/:ref.json' do
  lookup(params[:name], params[:ref])
end

get "/test" do
  UpdateAll.perform_async
end
