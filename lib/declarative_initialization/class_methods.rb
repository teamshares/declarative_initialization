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
      _set_up_attribute_readers(declared)
      _set_up_block_reader
      _define_initializer(declared, kwargs, post_initialize_block)
    end

    private

    def _declarative_initialization_readers
      @_declarative_initialization_readers ||= Set.new
    end

    def _reader_defined_by_us?(key)
      _declarative_initialization_readers.include?(key)
    end

    def _ancestor_with_reader(key)
      ancestors.drop(1).find do |ancestor|
        ancestor.instance_variable_defined?(:@_declarative_initialization_readers) &&
          ancestor.instance_variable_get(:@_declarative_initialization_readers).include?(key)
      end
    end

    def _set_up_attribute_readers(declared)
      declared.each { |key| _define_reader_if_needed(key) }
    end

    def _set_up_block_reader
      _define_reader_if_needed(:block, block_reader: true)
    end

    def _define_reader_if_needed(key, block_reader: false)
      return if _skip_existing_on_this_class?(key, block_reader: block_reader)
      return if _skip_inherited?(key, block_reader: block_reader)

      _declarative_initialization_readers.add(key)
      attr_reader key
    end

    def _skip_existing_on_this_class?(key, block_reader:)
      return false unless method_defined?(key, false)

      unless _reader_defined_by_us?(key)
        Internal.warn_method_exists(self, key, block_reader: block_reader)
      end
      true
    end

    def _skip_inherited?(key, block_reader:)
      return false unless method_defined?(key)

      unless _ancestor_with_reader(key)
        defined_in = Internal.method_owner_name(self, key)
        Internal.warn_method_exists(self, key, block_reader: block_reader, defined_in: defined_in)
      end
      true
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
