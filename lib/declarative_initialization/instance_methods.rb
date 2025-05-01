# frozen_string_literal: true

module DeclarativeInitialization
  module InstanceMethods
    private

    # Returns a logger instance. If Rails is available, uses Rails.logger,
    # otherwise creates a new Logger writing to STDOUT.
    # @return [Logger] The configured logger instance
    def __logger
      @__logger ||= if defined?(Rails) && Rails.respond_to?(:logger)
                      Rails.logger
                    else
                      logger = Logger.new($stdout)
                      logger.level = Logger::WARN
                      logger
                    end
    end

    def _validate_initialization_arguments!(class_name, given_args, given_kwargs, declared, defaults)
      raise ArgumentError, "[#{class_name}] Only keyword arguments are accepted" unless given_args.empty?

      missing = declared - given_kwargs.keys - defaults.keys
      extra = given_kwargs.keys - declared

      raise ArgumentError, "[#{class_name}] Missing required arguments: #{missing.join(", ")}" unless missing.empty?
      raise ArgumentError, "[#{class_name}] Unknown arguments: #{extra.join(", ")}" unless extra.empty?
    end
  end
end
