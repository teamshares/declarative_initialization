# frozen_string_literal: true

require "logger"
require "set"

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

    def display_name(klass)
      klass.name || "Anonymous Class"
    end

    def format_message(klass, message)
      "[#{display_name(klass)}] #{message}"
    end

    def validate_arguments!(klass, declared)
      return if declared.all?(Symbol)

      raise ArgumentError, format_message(klass, "All arguments to #initialize_with must be symbols")
    end

    def validate_initialization_arguments!(klass, given_args, given_kwargs, declared, defaults)
      raise ArgumentError, format_message(klass, "Only keyword arguments are accepted") unless given_args.empty?

      missing = declared - given_kwargs.keys - defaults.keys
      unless missing.empty?
        raise ArgumentError, format_message(klass, "Missing keyword argument(s): #{missing.join(", ")}")
      end

      extra = given_kwargs.keys - declared
      return if extra.empty?

      raise ArgumentError, format_message(klass, "Unknown keyword argument(s): #{extra.join(", ")}")
    end

    def warn_override(klass, key, block_reader:)
      return unless warn_override?

      location = override_location(klass, key)
      reader_type = block_reader ? "block" : "init-arg"
      logger.warn format_message(klass,
                                 "Method ##{key} already exists #{location} -- overriding with #{reader_type} reader")
    end

    def warn_override?
      return true if defined?(Rails) && Rails.respond_to?(:env) && (Rails.env.development? || Rails.env.test?)

      logger.level <= Logger::DEBUG
    end

    def override_location(klass, key)
      return "on this class" if klass.method_defined?(key, false)

      owner = klass.instance_method(key).owner
      "in #{owner.name || "an anonymous ancestor"}"
    end

    # Defensive copy for common mutable default values.
    #
    # Defaults passed to `initialize_with` are created once at class definition
    # time. Without copying, `[]` / `{}` / `Set.new` defaults can be shared across
    # instances and accidentally mutated.
    #
    # This is intentionally shallow, and only for common core mutable types.
    def copy_default(value)
      return value if value.nil? || value.frozen?

      case value
      when Array, Hash, Set, String
        value.dup
      else
        value
      end
    end
  end
end
