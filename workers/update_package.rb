require_relative "../github_client"
require_relative "./update_version"

class UpdatePackage
  include Sidekiq::Worker
  include GithubClient

  def perform(full_name)
    puts "Updating: #{full_name}"
    # List all files in tree
    client.tree(full_name, "gh-pages").tree.each do |file|
      if match_data = file["path"].match(/(.*)\.json\.js$/)
        ref = match_data[1]
        sha = file["sha"]

        # Create jobs to ingest the .json.js files into S3
        UpdateVersion.perform_async(full_name, ref, sha)
      end
    end
  end
end
