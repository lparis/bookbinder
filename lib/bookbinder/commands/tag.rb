require_relative '../book'
require_relative '../errors/cli_error'
require_relative '../deprecated_logger'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class Tag < BookbinderCommand
      include Commands::Naming

      def usage
        ["tag <git tag>", "Apply the specified <git tag> to your book and all sections of your book"]
      end

      def run(params)
        tag = params.first
        raise CliError::InvalidArguments unless tag

        book = Book.new(logger: @logger, full_name: config.book_repo, sections: config.sections)

        book.tag_self_and_sections_with tag

        @logger.log 'Success!'.green
        @logger.log " #{book.full_name.yellow} and its sections were tagged with #{tag.blue}"
        0
      end
    end
  end
end
