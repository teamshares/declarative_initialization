# frozen_string_literal: true

require_relative "declarative_initialization/version"
require_relative "declarative_initialization/internal"
require_relative "declarative_initialization/class_methods"

module DeclarativeInitialization
  def self.included(base)
    base.extend ClassMethods
  end
end

# Alias so you can also do `include InitializeWith`
InitializeWith = DeclarativeInitialization
