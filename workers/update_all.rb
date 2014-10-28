require_relative "./update_package"
require_relative "../github_client"

class UpdateAll
  include Sidekiq::Worker
  include GithubClient

  def perform
    # List all distri repos
    # Create jobs to ingest the .json.js files into S3
    client.repos("distri").map(&:full_name).each do |full_name|
      UpdatePackage.perform_async(full_name)
    end
  end
end
