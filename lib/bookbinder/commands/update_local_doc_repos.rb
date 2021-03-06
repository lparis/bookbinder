require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class UpdateLocalDocRepos < BookbinderCommand
      include Commands::Naming

      def usage
        [command_name,
         "Run `git pull` on all sections that exist at the same directory level as your book directory"]
      end

      def run(_)
        config.sections.map { |conf| repo_for(conf) }.each(&:update_local_copy)
        0
      end

      private

      def repo_for(section_config)
        local_repo_dir = File.absolute_path('../')
        GitHubRepository.new(logger: @logger, full_name: section_config['repository']['name'],
                             local_repo_dir: local_repo_dir, git_accessor: Git)
      end
    end
  end
end
