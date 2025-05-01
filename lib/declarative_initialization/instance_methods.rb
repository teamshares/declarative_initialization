# frozen_string_literal: true

module DeclarativeInitialization
  module InstanceMethods
    private

    def _validate_initialization_arguments!(class_name, given_args, given_kwargs, declared, defaults)
      raise ArgumentError, "[#{class_name}] Only keyword arguments are accepted" unless given_args.empty?

      missing = declared - given_kwargs.keys - defaults.keys
      extra = given_kwargs.keys - declared

      raise ArgumentError, "[#{class_name}] Missing keyword argument(s): #{missing.join(", ")}" unless missing.empty?
      raise ArgumentError, "[#{class_name}] Unknown keyword argument(s): #{extra.join(", ")}" unless extra.empty?
    end
  end
end
