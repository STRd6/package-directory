require 'digest/sha1'
require "fog"
require "stringio"
require "zlib"

require_relative "../github_client"

class UpdateVersion
  include Sidekiq::Worker
  include GithubClient

  def perform(full_name, ref, sha)
    raw = client.blob(full_name, sha, accept: "application/vnd.github.3.raw")

    content = "{\n#{raw.lines[1...-1].join}}\n"

    url = upload content, "application/json"

    puts url

    Sidekiq.redis do |redis|
      redis.set("#{full_name}:#{ref}", url)
    end
  end

  def upload(content, content_type)
    compressed_content = compress(content)
    compressed_key = "#{prefix}#{Digest::SHA1.hexdigest(compressed_content)}"

    bucket.files.create(
      :key => compressed_key,
      :body => compressed_content,
      "Content-Type" => content_type,
      "Content-Encoding" => "gzip",
      :public => true
    )

    url = "https://s3.amazonaws.com/#{bucket_name}/#{compressed_key}"

    return url
  end

  def compress(input)
    io = StringIO.new

    gz = Zlib::GzipWriter.new(io)
    gz.write input
    gz.close

    return io.string
  end

  def prefix
    ENV["S3_NAMESPACE"]
  end

  def bucket_name
    ENV["S3_BUCKET"]
  end

  def bucket
    return @bucket if @bucket

    connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => ENV["S3_KEY"],
      :aws_secret_access_key    => ENV["S3_SECRET"],
    })

    @bucket = connection.directories.get(bucket_name)
  end
end
