require_relative 'repositories/command_repository'
require_relative 'command_validator'
require_relative 'command_runner'
require_relative 'configuration'
require_relative 'colorizer'
require_relative 'terminal'

module Bookbinder
  class Cli
    def initialize(version_control_system)
      @version_control_system = version_control_system
    end

    def run(args)
      command_name, *command_arguments = args

      logger = DeprecatedLogger.new
      commands = Repositories::CommandRepository.new(logger, version_control_system)

      command_validator = CommandValidator.new(commands, commands.help.usage_message)
      command_runner = CommandRunner.new(logger, commands)
      command_name = command_name ? command_name : '--help'

      colorizer = Colorizer.new
      terminal = Terminal.new(colorizer)

      user_message = command_validator.validate(command_name)
      terminal.update(user_message)

      if user_message.error?
        return 1
      end

      begin
        command_runner.run command_name, command_arguments

      rescue Config::RemoteBindConfiguration::VersionUnsupportedError => e
        logger.error "config.yml at version '#{e.message}' has an unsupported API."
        1
      rescue Configuration::CredentialKeyError => e
        logger.error "#{e.message}, in credentials.yml"
        1
      rescue KeyError => e
        logger.error "#{e.message} from your configuration."
        1
      rescue CliError::UnknownCommand => e
        logger.log e.message
        1
      rescue RuntimeError => e
        logger.error e.message
        1
      end
    end

    private

    attr_reader :version_control_system

  end
end
