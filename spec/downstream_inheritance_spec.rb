# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  subject { klass.new(baz: 3) }

  let(:base_klass) do
    Class.new do
      include DeclarativeInitialization

      initialize_with :foo, bar: "default value"
    end
  end

  describe "with downstream initialize_with" do
    let(:klass) do
      Class.new(base_klass) do
        initialize_with :baz
      end
    end

    it "overrides initialize_with from super" do
      expect { subject }.not_to raise_error
      expect { klass.new(baz: 3, foo: 1, bar: 2) }.to raise_error(ArgumentError)
    end
  end

  describe "with downstream initialize_with calling super" do
    let(:klass) do
      Class.new(base_klass) do
        initialize_with :baz do
          super(foo: 1, bar: 2)
        end
      end
    end

    it "is not supported :(" do
      expect { subject }.to raise_error(TypeError)
    end
  end

  describe "with downstream initialize_with using fancy workaround" do
    let(:klass) do
      Class.new(base_klass) do
        initialize_with :baz do
          parent_initialize = method(:initialize).super_method
          parent_initialize.call(foo: 1, bar: 2)
        end
      end
    end

    it "works!" do
      expect { subject }.not_to raise_error
      expect(subject).to have_attributes(foo: 1, bar: 2, baz: 3)
    end
  end

  describe "with downstream initialize calling super" do
    let(:klass) do
      Class.new(base_klass) do
        attr_reader :baz

        def initialize(baz:)
          @baz = baz
          super(foo: 1, bar: 2)
        end
      end
    end

    it "calls initialize from super" do
      expect { subject }.not_to raise_error
      expect(subject).to have_attributes(foo: 1, bar: 2, baz: 3)
    end
  end
end
