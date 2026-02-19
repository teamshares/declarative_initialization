# DeclarativeInitialization

Boilerplate slows down devs and irritates everyone, plus the added cruft makes it harder to scan for the actual logic in a given file.

This is a small layer to support declarative initialization _specifically for simple keyword-based classes_.

## Usage

Given a standard ruby class like so:

```ruby
class SomeObject
  def initialize(foo:, bar:, baz: "default value")
    @foo = foo
    @bar = bar
    @baz = baz
  end

  attr_reader :foo, :bar, :baz
end
```

With this library it can be simplified to:

```ruby
class SomeObject
  include DeclarativeInitialization

  initialize_with :foo, :bar, baz: "default value"
end
```
## Quick note on naming

The gem name is `declarative_initialization` because there's already a very outdated gem claiming the `initialize_with` name.

We've set up an alias, however, so you can do either `include DeclarativeInitialization` _or_ `include InitializeWith`.

FWIW in practice at Teamshares we just `include DeclarativeInitialization` in the base class for all our View Components.

### Custom logic

Sometimes the existing `initialize` method also does other work, for instance setting initial values for additional instance variables that aren't passed in directly.

We support that by passing an optional block to `initialize_with` -- for instance, in the example above if the original version also set `@bang = foo * bar`, we could support that by changing the updated version to:

  ```ruby
  initialize_with :foo, :bar, baz: "default value" do
    @bang = @foo * @bar
  end
  ```

### Edge cases

* Accepting a block: this is handled automatically -- if a block was provided to the Foo.new call, it'll be made available as `@block`/`attr_reader :block`

* If a method with the same name already exists, we log a warning and do not create the `attr_reader`. In that case you'll need to reference the instance variable directly (e.g. `@foo` instead of `foo`).

  * **On this class:** If you define `def foo` before calling `initialize_with :foo`, we warn and skip.

  * **Inherited from an ancestor:** If a parent class defines `def foo`, we also warn and skip. This catches the case where a subclass expects `foo` to return the init value but an ancestor has a different implementation.

  * **Exception:** If the inherited method was created by an ancestor's `initialize_with` (i.e. our `attr_reader`), we skip silently—no warning, since the behavior is the same.

  * **Caution:** If the existing method doesn't read the instance variable, `@foo` is still set but calling `foo` returns something else, which can cause subtle bugs.

  * Because of this, **best practice when referencing variables in the post-initialize block is to use `@foo` rather than relying on the `foo` attr_reader**

* Due to ruby syntax limitations, we do not support referencing other fields directly in the declaration:

  * Does _not_ work:
    ```ruby
    initialize_with :user, company: user.employer
    ```
  * Workaround:
    ```ruby
    initialize_with :user, company: nil do
      @company ||= @user.employer
    end
    ```

* If using `initialize_with` on a subclass where the superclass defines `initialize`, we will _not_ automatically call `super`, because if we do we get this `RuntimeError`:
  > implicit argument passing of super from method defined by define_method() is not supported. Specify all arguments explicitly.

* If you need to call `super` from the block passed into `initialize_with` (unusual edge case, subclass requires different arguments than parent):

  * Does _not_ work (due to `instance_exec` changing execution context but _not_ the method lookup chain):
    ```ruby
    initialize_with :foo do
      super(bar: 123)
    end
    ```
  * Workaround _possible_ (but really, probably more understandable to just fall back to manually writing `def initialize`):
    ```ruby
    initialize_with :foo do
      parent_initialize = method(:initialize).super_method
      parent_initialize.call(bar: 123)
    end
    ```

* If you find yourself backed into a weird corner, just use a plain ole `def initialize`!  This library is meant to make the easy cases less work, but there's no requirement that you must use it for every super complex case you run into. :)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/teamshares/declarative_initialization. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/teamshares/declarative_initialization/blob/main/CODE_OF_CONDUCT.md).

## Code of Conduct

Everyone interacting in the DeclarativeInitialization project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/teamshares/declarative_initialization/blob/main/CODE_OF_CONDUCT.md).
