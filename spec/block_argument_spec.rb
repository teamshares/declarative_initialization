# frozen_string_literal: true

RSpec.describe DeclarativeInitialization do
  let(:klass) do
    Class.new do
      include DeclarativeInitialization
      initialize_with :foo
    end
  end

  it "doesn't record block unless given" do
    record = klass.new(foo: 1)
    expect(record.instance_variable_get("@block")).to be_nil
  end

  it "does record block when given" do
    record = klass.new(foo: 1) { "block" }
    expect(record.instance_variable_get("@block")).to be_a(Proc)
    expect(record.block.call).to eq("block")
  end
end
