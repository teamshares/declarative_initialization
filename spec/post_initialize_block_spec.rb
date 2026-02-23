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

  describe "referencing attributes in the block: @attr vs reader" do
    # When normalizing/setting defaults in the block (e.g. @foo = @foo.to_s),
    # confirm whether we must use the instance variable or can use the reader.

    let(:with_ivar) do
      Class.new do
        include DeclarativeInitialization

        initialize_with :foo do
          @foo = @foo.to_s
        end
      end
    end

    let(:with_reader) do
      Class.new do
        include DeclarativeInitialization

        initialize_with :foo do
          @foo = foo.to_s
        end
      end
    end

    it "allows normalizing using instance variable on both sides (@foo = @foo.to_s)" do
      expect(with_ivar.new(foo: 42).foo).to eq("42")
    end

    it "allows normalizing using reader on RHS (@foo = foo.to_s)" do
      expect(with_reader.new(foo: 42).foo).to eq("42")
    end

    it "both forms produce the same result" do
      [with_ivar, with_reader].each do |k|
        expect(k.new(foo: 100).foo).to eq("100")
        expect(k.new(foo: :sym).foo).to eq("sym")
        expect(k.new(foo: nil).foo).to eq("")
      end
    end
  end
end
