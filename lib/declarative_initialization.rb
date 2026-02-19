# frozen_string_literal: true

require_relative "declarative_initialization/version"
require_relative "declarative_initialization/class_methods"
require_relative "declarative_initialization/instance_methods"

module DeclarativeInitialization
  def self.included(base)
    base.include InstanceMethods
    base.extend ClassMethods
  end
end

# Alias so you can also do `include InitializeWith`
InitializeWith = DeclarativeInitialization
