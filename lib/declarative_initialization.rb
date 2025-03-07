# frozen_string_literal: true

require_relative "declarative_initialization/version"
require "logger"

module DeclarativeInitialization
  def self.included(base)
    base.class_eval do
      include InstanceMethods
      extend ClassMethods
    end
  end

  module ClassMethods
    def initialize_with(*args, **kwargs, &post_initialize_block)
      declared = args + kwargs.keys
      raise ArgumentError, "initialize_with expects to receive symbols" unless declared.all? { |arg| arg.is_a?(Symbol) }

      defaults = kwargs

      define_method(:initialize) do |*given_args, **given_kwargs, &block|
        class_name = self.class.name || "Anonymous Class"
        raise ArgumentError, "[#{class_name}] Only accepts keyword arguments" unless given_args.empty?

        missing = declared - given_kwargs.keys - defaults.keys
        extra = given_kwargs.keys - declared

        raise ArgumentError, "[#{class_name}] Missing keyword arguments: #{missing.join(", ")}" unless missing.empty?
        raise ArgumentError, "[#{class_name}] Unknown keyword arguments: #{extra.join(", ")}" unless extra.empty?

        declared.each do |key|
          instance_variable_set(:"@#{key}", given_kwargs.fetch(key, defaults[key]))
          if respond_to?(key, true)
            __logger.warn "Method ##{key} already exists on #{self.class.name}. Skipping attr_reader generation."
          else
            self.class.send(:attr_reader, key)
          end
        end

        if block # Automatically record any block passed to .new as an instance variable
          instance_variable_set(:@block, block)
          self.class.send(:attr_reader, :block) unless respond_to?(:block)
        end

        instance_exec(&post_initialize_block) if post_initialize_block
      end
    end
  end

  module InstanceMethods
    def __logger
      @__logger ||= begin
        Rails.logger
      rescue NameError
        Logger.new($stdout)
      end
    end
  end
end

# Set up an alias so you can also do `include InitializeWith`
module InitializeWith
  def self.included(base)
    base.class_eval do
      include DeclarativeInitialization
    end
  end
end
