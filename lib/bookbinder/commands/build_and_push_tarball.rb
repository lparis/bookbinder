require_relative 'naming'
require_relative 'bookbinder_command'
require_relative '../archive'

module Bookbinder
  module Commands
    class BuildAndPushTarball < BookbinderCommand
      include Commands::Naming

      class MissingBuildNumber < StandardError
        def initialize
          super 'You must set $BUILD_NUMBER to push an identifiable build.'
        end
      end

      def usage
        [command_name,
         "Create a tarball from the final_app directory and push to the S3 bucket specified in your credentials.yml"]
      end

      def run(_)
        raise MissingBuildNumber unless ENV['BUILD_NUMBER']
        config = configuration_fetcher.fetch_config
        aws_credentials = config.aws_credentials
        archive = Archive.new(logger: @logger, key: aws_credentials.access_key, secret: aws_credentials.secret_key)
        archive.create_and_upload_tarball(build_number: ENV['BUILD_NUMBER'], bucket: aws_credentials.green_builds_bucket,
                                          namespace: GitHubRepository.new(logger: @logger, full_name: config.book_repo, git_accessor: Git).short_name)
        0
      end
    end
  end
end
