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

    let(:log_double) { instance_double(Logger) }

    before do
      allow_any_instance_of(klass).to receive(:__logger).and_return(log_double)
    end

    it "does not override existing readers" do
      expect(log_double).to receive(:warn)
      expect(subject.foo).to eq(100)
    end
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
end
