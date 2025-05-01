# frozen_string_literal: true

module DeclarativeInitialization
  module ClassMethods
    # Defines an initializer expecting the specified keyword arguments.
    # @param args [Array<Symbol>] Required keyword arguments
    # @param kwargs [Hash<Symbol, Object>] Optional keyword arguments (required, but have default values)
    # @param post_initialize_block [Proc] Block to execute after initialization (optional)
    def initialize_with(*args, **kwargs, &post_initialize_block)
      declared = args + kwargs.keys
      _validate_arguments!(declared)

      _setup_attribute_readers(declared)
      _setup_block_reader
      _define_initializer(declared, kwargs, post_initialize_block)
    end

    private

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

      raise ArgumentError, "All arguments must be symbols"
    end

    def _setup_attribute_readers(declared)
      declared.each do |key|
        if method_defined?(key)
          _logger.warn "Method ##{key} already exists on #{name}. Skipping attr_reader generation."
        else
          attr_reader key
        end
      end
    end

    def _setup_block_reader
      if method_defined?(:block)
        _logger.warn "Method #block already exists on #{name}. Will NOT be able to reference a block passed to #new as #block (use @block instead)."
      else
        attr_reader :block
      end
    end

    def _define_initializer(declared, defaults, post_initialize_block)
      define_method(:initialize) do |*given_args, **given_kwargs, &block|
        class_name = self.class.name || "Anonymous Class"
        _validate_initialization_arguments!(class_name, given_args, given_kwargs, declared, defaults)

        declared.each do |key|
          instance_variable_set(:"@#{key}", given_kwargs.fetch(key, defaults[key]))
        end

        instance_variable_set(:@block, block) if block
        instance_exec(&post_initialize_block) if post_initialize_block
      end
    end
  end
end
