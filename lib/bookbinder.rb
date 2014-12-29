require 'fog'
require 'tmpdir'
require 'ansi'
require 'faraday'
require 'faraday_middleware'
require 'octokit'
require 'padrino-contrib'
require 'middleman-syntax'
require 'middleman-core/cli'
require 'middleman-core/profiling'
require 'anemone'
require 'css_parser'
require 'vienna'
require 'popen4'
require 'puma'

module Bookbinder
  class VersionUnsupportedError < StandardError;
    def initialize(msg=nil)
      super
    end
  end
end
#require_relative 'bookbinder/shell_out'
require_relative 'bookbinder/bookbinder_logger'
require_relative 'bookbinder/git_client'
#require_relative 'bookbinder/repository'
require_relative 'bookbinder/section'
require_relative 'bookbinder/book'
require_relative 'bookbinder/code_example'
require_relative 'bookbinder/remote_yaml_credential_provider'
require_relative 'bookbinder/configuration'
require_relative 'bookbinder/configuration_fetcher'
require_relative 'bookbinder/configuration_validator'
require_relative 'bookbinder/css_link_checker'
require_relative 'bookbinder/sitemap_generator'
require_relative 'bookbinder/sieve'
require_relative 'bookbinder/stabilimentum'
require_relative 'bookbinder/server_director'
require_relative 'bookbinder/spider'

require_relative 'bookbinder/archive'
require_relative 'bookbinder/pdf_generator'
require_relative 'bookbinder/middleman_runner'
require_relative 'bookbinder/publisher'
require_relative 'bookbinder/cf_command_runner'
require_relative 'bookbinder/pusher'
require_relative 'bookbinder/artifact_namer'
require_relative 'bookbinder/distributor'

require_relative 'bookbinder/bookbinder_command'
require_relative 'bookbinder/commands/build_and_push_tarball'
require_relative 'bookbinder/commands/publish'
require_relative 'bookbinder/commands/push_local_to_staging'
require_relative 'bookbinder/commands/push_to_prod'
require_relative 'bookbinder/commands/run_publish_ci'
require_relative 'bookbinder/commands/update_local_doc_repos'
require_relative 'bookbinder/commands/tag'
require_relative 'bookbinder/commands/generate_pdf'

require_relative 'bookbinder/usage_messenger'

require_relative 'bookbinder/cli'

# Finds the project root for both spec & production
GEM_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))
