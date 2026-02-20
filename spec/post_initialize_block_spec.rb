# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  let(:klass) do
    Class.new do
      include DeclarativeInitialization

      initialize_with :foo, bar: "default value" do
        @baz = foo
      end
    end
  end

  describe "executes the post-initialization block" do
    subject { klass.new(foo: 1, bar: 2) }

    it { is_expected.to have_attributes(foo: 1, bar: 2) }
    it { expect(subject.instance_variable_get("@baz")).to eq(1) }
  end
end
