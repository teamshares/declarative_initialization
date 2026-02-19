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

  # =============================================================================
  # OVERRIDE BEHAVIOR AND OPTIONAL WARNING COVERAGE
  # =============================================================================
  #
  # Matrix of scenarios for attribute readers:
  #   OVERRIDE + OPTIONAL WARN cases:
  #     - User method on THIS class before initialize_with
  #     - User method on ANCESTOR (inherited, not our reader)
  #   NO-WARN + NO-OVERRIDE cases:
  #     - Reload (we defined it on this class)
  #     - Inherited from ancestor's initialize_with (our reader)
  #     - User method defined AFTER initialize_with (user's method wins)
  #     - No conflicting method
  #
  # Same matrix applies to :block reader
  # =============================================================================

  describe "override and warning scenarios" do
    let(:logger) { instance_double(Logger, level: Logger::DEBUG) }

    before do
      allow(DeclarativeInitialization::Internal).to receive(:logger).and_return(logger)
      allow(DeclarativeInitialization::Internal).to receive(:should_warn_override?).and_return(true)
    end

    def attr_override_warning(key, location: "on this class")
      "[Anonymous Class] Method ##{key} already exists #{location} -- overriding with init-arg reader"
    end

    def block_override_warning(location: "on this class")
      "[Anonymous Class] Method #block already exists #{location} -- overriding with block reader"
    end

    # =========================================================================
    # OVERRIDE + OPTIONAL WARN CASES
    # =========================================================================

    describe "user method on THIS class before initialize_with" do
      let(:klass) do
        Class.new do
          def foo = "user-defined"
          include DeclarativeInitialization
        end
      end

      it "WARNS when overriding" do
        expect(logger).to receive(:warn).with(attr_override_warning(:foo))
        klass.initialize_with(:foo)
      end

      it "overrides user method, foo returns init-arg value" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo)
        instance = klass.new(foo: 123)
        expect(instance.foo).to eq(123)
      end
    end

    describe "user method on ANCESTOR (inherited)" do
      let(:parent_klass) do
        Class.new do
          def foo = "parent custom"
        end
      end

      let(:klass) { Class.new(parent_klass) { include DeclarativeInitialization } }

      it "WARNS when overriding with ancestor class name (anonymous)" do
        expect(logger).to receive(:warn).with(attr_override_warning(:foo, location: "in an anonymous ancestor"))
        klass.initialize_with(:foo)
      end

      it "overrides inherited method, foo returns init-arg value" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo)
        instance = klass.new(foo: 123)
        expect(instance.foo).to eq(123)
      end
    end

    describe ":block reader with user #block on THIS class" do
      let(:klass) do
        Class.new do
          def block = "user block"
          include DeclarativeInitialization
        end
      end

      it "WARNS when overriding with block-specific message" do
        expect(logger).to receive(:warn).with(block_override_warning)
        klass.initialize_with(:foo)
      end

      it "overrides user's #block, returns block passed to new" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo)
        my_block = proc { "test" }
        instance = klass.new(foo: 1, &my_block)
        expect(instance.block).to eq(my_block)
      end
    end

    describe ":block reader with user #block on ANCESTOR" do
      let(:parent_klass) do
        Class.new do
          def block = "parent block"
        end
      end

      let(:klass) { Class.new(parent_klass) { include DeclarativeInitialization } }

      it "WARNS when overriding with ancestor class name (anonymous)" do
        expect(logger).to receive(:warn).with(block_override_warning(location: "in an anonymous ancestor"))
        klass.initialize_with(:foo)
      end

      it "overrides inherited #block, returns block passed to new" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo)
        my_block = proc { "test" }
        instance = klass.new(foo: 1, &my_block)
        expect(instance.block).to eq(my_block)
      end
    end

    describe "multiple attributes, some conflict" do
      let(:klass) do
        Class.new do
          def bar = "user bar"
          include DeclarativeInitialization
        end
      end

      it "WARNS only for conflicting attribute" do
        expect(logger).to receive(:warn).with(attr_override_warning(:bar)).once
        klass.initialize_with(:foo, :bar, baz: "default")
      end

      it "overrides conflicting, all attributes return init-arg values" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo, :bar, baz: "default")
        instance = klass.new(foo: 1, bar: 2, baz: 3)
        expect(instance.foo).to eq(1)
        expect(instance.bar).to eq(2)
        expect(instance.baz).to eq(3)
      end
    end

    # =========================================================================
    # NO-WARN CASES
    # =========================================================================

    describe "no conflicting method (normal case)" do
      let(:klass) { Class.new { include DeclarativeInitialization } }

      it "does NOT warn" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo, :bar, baz: "default")
      end

      it "defines all readers" do
        klass.initialize_with(:foo, :bar, baz: "default")
        instance = klass.new(foo: 1, bar: 2)
        expect(instance).to have_attributes(foo: 1, bar: 2, baz: "default")
        expect(instance).to respond_to(:block)
      end
    end

    describe "user method defined AFTER initialize_with" do
      let(:klass) do
        Class.new do
          include DeclarativeInitialization
          initialize_with :foo

          def foo = "user-override-after"
        end
      end

      it "does NOT warn (we define first)" do
        expect(logger).not_to receive(:warn)
      end

      it "user's method takes precedence" do
        instance = klass.new(foo: 123)
        expect(instance.foo).to eq("user-override-after")
        expect(instance.instance_variable_get("@foo")).to eq(123)
      end
    end

    describe "reload: initialize_with called twice" do
      let(:klass) { Class.new { include DeclarativeInitialization } }

      it "does NOT warn on second call" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo)
        klass.initialize_with(:foo)
      end

      it "still works after reload" do
        klass.initialize_with(:foo)
        klass.initialize_with(:foo)
        expect(klass.new(foo: 42).foo).to eq(42)
      end

      it "does NOT warn when adding attributes on reload" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo)
        klass.initialize_with(:foo, :bar)
      end

      it ":block reader also doesn't warn on reload" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo)
        klass.initialize_with(:foo)
        my_block = proc { "test" }
        expect(klass.new(foo: 1, &my_block).block).to eq(my_block)
      end
    end

    describe "inherited from ancestor's initialize_with" do
      let(:parent_klass) do
        Class.new do
          include DeclarativeInitialization
          initialize_with :foo
        end
      end

      let(:klass) { Class.new(parent_klass) }

      it "does NOT warn when re-declaring parent's attribute" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo, :bar)
      end

      it "child uses parent's reader" do
        klass.initialize_with(:foo, :bar)
        expect(klass.instance_method(:foo).owner).to eq(parent_klass)
      end

      it "works correctly" do
        klass.initialize_with(:foo, :bar)
        expect(klass.new(foo: 1, bar: 2)).to have_attributes(foo: 1, bar: 2)
      end
    end

    describe "grandchild with ancestor chain using initialize_with" do
      let(:grandparent_klass) do
        Class.new do
          include DeclarativeInitialization
          initialize_with :foo
        end
      end

      let(:parent_klass) do
        Class.new(grandparent_klass) do
          initialize_with :foo, :bar
        end
      end

      let(:klass) { Class.new(parent_klass) }

      it "does NOT warn when re-declaring ancestors' attributes" do
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo, :bar, :baz)
      end

      it "works correctly with all attributes" do
        klass.initialize_with(:foo, :bar, :baz)
        expect(klass.new(foo: 1, bar: 2, baz: 3)).to have_attributes(foo: 1, bar: 2, baz: 3)
      end
    end

    # =========================================================================
    # MIXED CASES
    # =========================================================================

    describe "user method on named ancestor class" do
      before do
        stub_const("NamedParent", Class.new do
          def foo = "named parent method"
        end)
      end

      let(:klass) { Class.new(NamedParent) { include DeclarativeInitialization } }

      it "WARNS when overriding with actual class name" do
        expect(logger).to receive(:warn).with(attr_override_warning(:foo, location: "in NamedParent"))
        klass.initialize_with(:foo)
      end

      it "overrides ancestor method, foo returns init-arg value" do
        allow(logger).to receive(:warn)
        klass.initialize_with(:foo)
        instance = klass.new(foo: 123)
        expect(instance.foo).to eq(123)
      end
    end

    describe "grandparent user method, parent/child use initialize_with" do
      let(:grandparent_klass) do
        Class.new do
          def foo = "grandparent custom"
        end
      end

      let(:parent_klass) do
        Class.new(grandparent_klass) do
          include DeclarativeInitialization
        end
      end

      let(:klass) { Class.new(parent_klass) }

      it "parent WARNS when overriding with grandparent class name (anonymous)" do
        expect(logger).to receive(:warn).with(attr_override_warning(:foo, location: "in an anonymous ancestor"))
        parent_klass.initialize_with(:foo)
      end

      it "child does NOT warn because parent already has our reader" do
        allow(logger).to receive(:warn)
        parent_klass.initialize_with(:foo)
        expect(logger).not_to receive(:warn)
        klass.initialize_with(:foo, :bar)
      end

      it "parent's reader is used, init-arg value returned" do
        allow(logger).to receive(:warn)
        parent_klass.initialize_with(:foo)
        klass.initialize_with(:foo, :bar)
        instance = klass.new(foo: 1, bar: 2)
        expect(instance.foo).to eq(1)
        expect(instance.bar).to eq(2)
      end
    end
  end
end
