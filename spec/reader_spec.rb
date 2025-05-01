# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  subject { klass.new(foo: 1) }

  describe "allows overriding the default attr_reader" do
    let(:klass) do
      Class.new do
        include DeclarativeInitialization
        initialize_with :foo

        def foo = @foo * 100
      end
    end

    it { expect(subject.foo).to eq(100) }
  end

  describe "allows overriding the value read by the attr_reader" do
    let(:klass) do
      Class.new do
        include DeclarativeInitialization
        initialize_with :foo do
          @foo *= 100
        end
      end
    end

    it { expect(subject.foo).to eq(100) }
  end

  describe "allows overriding the value read by the attr_reader without the instance variable" do
    let(:klass) do
      Class.new do
        include DeclarativeInitialization
        initialize_with :foo do
          @foo = foo * 100
        end
      end
    end

    it { expect(subject.foo).to eq(100) }
  end

  describe "does not create attr_reader if method already exists" do
    let(:klass) do
      Class.new do
        def foo = "original"
        include DeclarativeInitialization
        initialize_with :foo
      end
    end

    it { expect(subject.foo).to eq("original") }
    it { expect(subject.instance_variable_get("@foo")).to eq(1) }
  end
end
