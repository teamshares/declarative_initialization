# frozen_string_literal: true

require "set"

module DeclarativeInitialization
  module ClassMethods
    # Defines an initializer expecting the specified keyword arguments.
    # @param args [Array<Symbol>] Required keyword arguments
    # @param kwargs [Hash<Symbol, Object>] Optional keyword arguments with default values
    # @param post_initialize_block [Proc] Block to execute after initialization (optional)
    def initialize_with(*args, **kwargs, &post_initialize_block)
      declared = args + kwargs.keys
      Internal.validate_arguments!(self, declared)
      declared.each { |key| _define_reader(key) }
      _define_reader(:block, block_reader: true)
      _define_initializer(declared, kwargs, post_initialize_block)
    end

    private

    def _declarative_initialization_readers
      @_declarative_initialization_readers ||= Set.new
    end

    def _ancestor_with_reader(key)
      ancestors.drop(1).find do |ancestor|
        ancestor.instance_variable_defined?(:@_declarative_initialization_readers) &&
          ancestor.instance_variable_get(:@_declarative_initialization_readers).include?(key)
      end
    end

    def _define_reader(key, block_reader: false)
      return if _declarative_initialization_readers.include?(key)
      return if _ancestor_with_reader(key)

      Internal.warn_override(self, key, block_reader: block_reader) if method_defined?(key)

      _declarative_initialization_readers.add(key)
      attr_reader key
    end

    def _define_initializer(declared, defaults, post_initialize_block)
      define_method(:initialize) do |*given_args, **given_kwargs, &given_block|
        Internal.validate_initialization_arguments!(self.class, given_args, given_kwargs, declared, defaults)

        merged = defaults.merge(given_kwargs)
        declared.each { |key| instance_variable_set(:"@#{key}", merged[key]) }

        instance_variable_set(:@block, given_block) if given_block
        instance_exec(&post_initialize_block) if post_initialize_block
      end
    end
  end
end
