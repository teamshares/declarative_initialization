# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  shared_examples "basic interface" do
    describe "when called with valid arguments" do
      subject { klass.new(foo: 1, bar: 2) }

      it { is_expected.to have_attributes(foo: 1, bar: 2) }
    end

    describe "when called with missing optional argument" do
      subject { klass.new(foo: 1) }

      it { expect { subject }.not_to raise_error }
      it { is_expected.to have_attributes(foo: 1, bar: "default value") }
    end

    describe "when called with missing required arguments" do
      subject { klass.new(bar: 1) }

      it { expect { subject }.to raise_error(ArgumentError, "[Anonymous Class] Missing keyword argument(s): foo") }
    end

    describe "when called with extra arguments" do
      subject { klass.new(foo: 1, bar: 2, baz: 3) }

      it { expect { subject }.to raise_error(ArgumentError, "[Anonymous Class] Unknown keyword argument(s): baz") }
    end

    describe "when called with positional arguments" do
      subject { klass.new(1, 2) }

      it { expect { subject }.to raise_error(ArgumentError, "[Anonymous Class] Only keyword arguments are accepted") }
    end
  end

  let(:base_klass) do
    Class.new do
      include DeclarativeInitialization
      initialize_with :foo, bar: "default value"
    end
  end

  describe "works when applied directly to a class" do
    let(:klass) { base_klass }

    it_behaves_like "basic interface"
  end

  describe "works with inheritance" do
    let(:klass) { Class.new(base_klass) }

    it_behaves_like "basic interface"
  end
end
