# frozen_string_literal: true

require "logger"

module DeclarativeInitialization
  # Internal helpers that don't need to be injected into user classes.
  # All methods are module functions - stateless and callable as Internal.method_name
  module Internal
    module_function

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger)
                    Rails.logger
                  else
                    Logger.new($stdout).tap { |l| l.level = Logger::WARN }
                  end
    end

    def class_name(klass)
      klass.name || "Anonymous Class"
    end

    def prefixed(klass, message)
      "[#{class_name(klass)}] #{message}"
    end

    def validate_arguments!(klass, declared)
      return if declared.all? { |arg| arg.is_a?(Symbol) }

      raise ArgumentError, prefixed(klass, "All arguments to #initialize_with must be symbols")
    end

    def validate_initialization_arguments!(klass, given_args, given_kwargs, declared, defaults)
      raise ArgumentError, prefixed(klass, "Only keyword arguments are accepted") unless given_args.empty?

      missing = declared - given_kwargs.keys - defaults.keys
      raise ArgumentError, prefixed(klass, "Missing keyword argument(s): #{missing.join(", ")}") unless missing.empty?

      extra = given_kwargs.keys - declared
      raise ArgumentError, prefixed(klass, "Unknown keyword argument(s): #{extra.join(", ")}") unless extra.empty?
    end

    def warn_override(klass, key, block_reader:)
      return unless should_warn_override?

      location = override_location(klass, key)
      reader_type = block_reader ? "block" : "init-arg"
      logger.warn prefixed(klass, "Method ##{key} already exists #{location} -- overriding with #{reader_type} reader")
    end

    def should_warn_override?
      return true if defined?(Rails) && Rails.respond_to?(:env) && (Rails.env.development? || Rails.env.test?)

      logger.level <= Logger::DEBUG
    end

    def override_location(klass, key)
      if klass.method_defined?(key, false)
        "on this class"
      else
        owner = klass.instance_method(key).owner
        "in #{owner.name || "an anonymous ancestor"}"
      end
    end
  end
end
