# frozen_string_literal: true

module DeclarativeInitialization
  module InstanceMethods
    private

    def _class_name
      self.class.name || "Anonymous Class"
    end

    def _prefixed(message)
      "[#{_class_name}] #{message}"
    end

    def _validate_initialization_arguments!(given_args, given_kwargs, declared, defaults)
      raise ArgumentError, _prefixed("Only keyword arguments are accepted") unless given_args.empty?

      missing = declared - given_kwargs.keys - defaults.keys
      raise ArgumentError, _prefixed("Missing keyword argument(s): #{missing.join(", ")}") unless missing.empty?

      extra = given_kwargs.keys - declared
      raise ArgumentError, _prefixed("Unknown keyword argument(s): #{extra.join(", ")}") unless extra.empty?
    end
  end
end
