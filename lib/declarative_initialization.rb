# frozen_string_literal: true

require_relative "declarative_initialization/version"
require_relative "declarative_initialization/class_methods"
require_relative "declarative_initialization/instance_methods"
require "logger"

module DeclarativeInitialization
  def self.included(base)
    base.class_eval do
      include InstanceMethods
      extend ClassMethods
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
