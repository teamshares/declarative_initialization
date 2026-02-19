# frozen_string_literal: true

require "logger"
require "set"

module DeclarativeInitialization
  module ClassMethods
    # Defines an initializer expecting the specified keyword arguments.
    # @param args [Array<Symbol>] Required keyword arguments
    # @param kwargs [Hash<Symbol, Object>] Optional keyword arguments (required, but have default values)
    # @param post_initialize_block [Proc] Block to execute after initialization (optional)
    def initialize_with(*args, **kwargs, &post_initialize_block)
      declared = args + kwargs.keys
      _validate_arguments!(declared)

      _set_up_attribute_readers(declared)
      _set_up_block_reader
      _define_initializer(declared, kwargs, post_initialize_block)
    end

    private

    def _class_name
      name || "Anonymous Class"
    end

    def _logger
      @_logger ||= if defined?(Rails) && Rails.respond_to?(:logger)
                     Rails.logger
                   else
                     logger = Logger.new($stdout)
                     logger.level = Logger::WARN
                     logger
                   end
    end

    def _validate_arguments!(declared)
      return if declared.all? { |arg| arg.is_a?(Symbol) }

      raise ArgumentError, "[#{_class_name}] All arguments to #initialize_with must be symbols"
    end

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

    def _ancestor_name(ancestor)
      ancestor.name || "an anonymous ancestor"
    end

    def _method_owner_name(key)
      owner = instance_method(key).owner
      owner.name || "an anonymous ancestor"
    end

    def _set_up_attribute_readers(declared)
      declared.each do |key|
        _define_reader_if_needed(key)
      end
    end

    def _set_up_block_reader
      _define_reader_if_needed(:block, block_reader: true)
    end

    def _define_reader_if_needed(key, block_reader: false)
      if method_defined?(key, false)
        # Method defined on THIS class (not inherited)
        if _reader_defined_by_us?(key)
          # We defined it (e.g. reload) - silently skip
          return
        else
          # User defined it on this class - warn and skip
          _warn_method_exists(key, block_reader: block_reader)
          return
        end
      elsif method_defined?(key)
        # Method inherited - check if it's our reader or a user method
        if _ancestor_with_reader(key)
          # Ancestor's initialize_with defined it - skip silently (same behavior)
          return
        else
          # User-defined method on ancestor - warn and skip
          _warn_method_exists(key, block_reader: block_reader, defined_in: _method_owner_name(key))
          return
        end
      end

      # Method doesn't exist - define it and track
      _declarative_initialization_readers.add(key)
      attr_reader key
    end

    def _warn_method_exists(key, block_reader: false, defined_in: nil)
      location = defined_in ? "in #{defined_in}" : "on this class"
      if block_reader
        _logger.warn "[#{_class_name}] Method ##{key} already exists #{location} -- may NOT be able to reference " \
                     "a block passed to #new as ##{key} (use @#{key} instead)"
      else
        _logger.warn "[#{_class_name}] Method ##{key} already exists #{location} -- skipping attr_reader generation " \
                     "(use @#{key} in post-initialize block if you need the value passed to #new)"
      end
    end

    def _define_initializer(declared, defaults, post_initialize_block)
      define_method(:initialize) do |*given_args, **given_kwargs, &given_block|
        class_name = self.class.name || "Anonymous Class"
        _validate_initialization_arguments!(class_name, given_args, given_kwargs, declared, defaults)

        declared.each do |key|
          instance_variable_set(:"@#{key}", given_kwargs.fetch(key, defaults[key]))
        end

        instance_variable_set(:@block, given_block) if given_block
        instance_exec(&post_initialize_block) if post_initialize_block
      end
    end
  end
end
