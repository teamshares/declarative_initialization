# frozen_string_literal: true

require "logger"

module DeclarativeInitialization
  # Internal helpers that don't need to be injected into user classes.
  # All methods are module functions - stateless and callable as Internal.method_name
  module Internal
    module_function

    def class_name(klass)
      klass.name || "Anonymous Class"
    end

    def prefixed(klass, message)
      "[#{class_name(klass)}] #{message}"
    end

    def logger
      @logger ||= if defined?(Rails) && Rails.respond_to?(:logger)
                    Rails.logger
                  else
                    Logger.new($stdout).tap { |l| l.level = Logger::WARN }
                  end
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

    def method_owner_name(klass, key)
      owner = klass.instance_method(key).owner
      owner.name || "an anonymous ancestor"
    end

    def warn_method_exists(klass, key, block_reader:, defined_in: nil)
      location = defined_in ? "in #{defined_in}" : "on this class"
      message = block_reader ? block_warning(key, location) : attr_warning(key, location)
      logger.warn prefixed(klass, message)
    end

    def attr_warning(key, location)
      "Method ##{key} already exists #{location} -- skipping attr_reader generation " \
      "(use @#{key} in post-initialize block if you need the value passed to #new)"
    end

    def block_warning(key, location)
      "Method ##{key} already exists #{location} -- may NOT be able to reference " \
      "a block passed to #new as ##{key} (use @#{key} instead)"
    end
  end
end
