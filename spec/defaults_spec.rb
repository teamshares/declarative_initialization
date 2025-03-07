# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  subject { klass.new(foo: 1).bar }

  describe "defaults cannot directly reference other fields" do
    let(:klass) do
      Class.new do
        include DeclarativeInitialization
        initialize_with :foo, bar: foo
      end
    end

    it { expect { subject }.to raise_error(NameError) }
  end

  describe "but a workaround is available" do
    let(:klass) do
      Class.new do
        include DeclarativeInitialization
        initialize_with :foo, bar: nil do
          @bar ||= foo
        end
      end
    end

    it { is_expected.to eq(1) }
  end
end
