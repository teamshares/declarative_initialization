# frozen_string_literal: true

require "set"

module DeclarativeInitialization
  module ClassMethods
    # Defines an initializer expecting the specified keyword arguments.
    # @param args [Array<Symbol>] Required keyword arguments
    # @param kwargs [Hash<Symbol, Object>] Optional keyword arguments with default values
    # @param post_initialize [Proc] Block to execute after initialization (optional)
    def initialize_with(*args, **kwargs, &post_initialize)
      declared = args + kwargs.keys
      Internal.validate_arguments!(self, declared)
      declared.each { |key| _define_reader(key) }
      _define_reader(:block, block_reader: true)
      _define_generated_initializer(declared, kwargs, post_initialize)
    end

    private

    def _declared_readers
      @_declared_readers ||= Set.new
    end

    def _ancestor_declared_reader?(key)
      ancestors.drop(1).any? do |ancestor|
        ancestor.instance_variable_get(:@_declared_readers)&.include?(key)
      end
    end

    def _define_reader(key, block_reader: false)
      return if _declared_readers.include?(key)
      return if _ancestor_declared_reader?(key)

      Internal.warn_override(self, key, block_reader: block_reader) if method_defined?(key)

      _declared_readers.add(key)
      attr_reader key
    end

    def _define_generated_initializer(declared, defaults, post_initialize)
      define_method(:initialize) do |*given_args, **given_kwargs, &given_block|
        Internal.validate_initialization_arguments!(self.class, given_args, given_kwargs, declared, defaults)

        defaults.each do |key, value|
          next if given_kwargs.key?(key)

          instance_variable_set(:"@#{key}", Internal.copy_default(value))
        end

        given_kwargs.each { |key, value| instance_variable_set(:"@#{key}", value) }

        instance_variable_set(:@block, given_block) if given_block
        instance_exec(&post_initialize) if post_initialize
      end
    end
  end
end
