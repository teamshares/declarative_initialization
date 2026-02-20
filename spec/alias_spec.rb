# frozen_string_literal: true

RSpec.describe InitializeWith do
  let(:klass) do
    Class.new do
      include InitializeWith

      initialize_with :foo, bar: "default value"
    end
  end

  describe "acts an as alias for DeclarativeInitialization" do
    subject { klass.new(foo: 1, bar: 2) }

    it { is_expected.to have_attributes(foo: 1, bar: 2) }
  end
end
