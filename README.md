# DeclarativeInitialization

Declare a class’s keyword inputs once and get a keyword-only `initialize` with assignments, readers, and helpful argument errors.

- **Keyword-only initializer**: rejects positional args and unknown keywords
- **Assignments**: sets `@keyword` instance variables from declared inputs
- **Readers**: defines `attr_reader` for each input (and a `block` reader)
- **Defaults**: supports optional keywords with default values
- **No dependencies**: plain Ruby (\(>= 3.0\))

## When to use it

Use this when you have small POROs that take keyword inputs and you’re tired of repeating the same initializer boilerplate:

- **Service / command objects** that take dependencies and parameters
- **Value objects** with a fixed set of attributes
- **Configuration objects** with a handful of optional flags
- **Components / presenters** that accept a stable set of inputs

If you need complex inheritance initialization, multiple initializer “shapes”, or highly dynamic defaults, a handwritten `initialize` may be clearer.

## Installation

Add to your Gemfile:

```ruby
gem "declarative_initialization"
```

Then install:

```bash
bundle install
```

In non-Bundler contexts, require it directly:

```ruby
require "declarative_initialization"
```

## Quick start

```ruby
class UserGreeter
  include DeclarativeInitialization

  initialize_with :user

  def call
    "Hello, #{user.name}!"
  end
end

UserGreeter.new(user: current_user).call
# => "Hello, Alice!"

UserGreeter.new
# ArgumentError: [UserGreeter] Missing keyword argument(s): user

UserGreeter.new(user: current_user, extra: true)
# ArgumentError: [UserGreeter] Unknown keyword argument(s): extra
```

## Usage

### Required vs optional keywords (defaults)

Declare required keywords as symbols, and optional keywords as keyword arguments:

```ruby
class Search
  include DeclarativeInitialization

  initialize_with :query, limit: 10, order: :desc

  def call
    results = perform_search(query).take(limit)
    order == :desc ? results.reverse : results
  end
end

Search.new(query: "ruby").call
Search.new(query: "ruby", limit: 50).call
```

### Post-initialize hook

Pass a block to `initialize_with` to run code after assignments. The block runs in the instance context.

```ruby
class Rectangle
  include DeclarativeInitialization

  initialize_with :width, :height do
    raise ArgumentError, "Dimensions must be positive" if width <= 0 || height <= 0
    @area = width * height
  end

  attr_reader :area
end
```

### Capturing a block passed to `.new`

If the caller passes a block to `.new`, it’s stored in `@block` and available via the `block` reader.

```ruby
class Wrapper
  include DeclarativeInitialization

  initialize_with :tag

  def render
    "<#{tag}>#{block&.call}</#{tag}>"
  end
end

Wrapper.new(tag: "div") { "Content" }.render
# => "<div>Content</div>"
```

## Behavior notes / gotchas

### Only keyword arguments are accepted

The generated initializer is keyword-only. Passing positional arguments raises an `ArgumentError`.

### Readers are public by default

Inputs are exposed with `attr_reader`. If you prefer private readers, make them private after the declaration:

```ruby
class Example
  include DeclarativeInitialization
  initialize_with :user, admin: false

  private :user, :admin
end
```

### Defaults are literal values

Defaults are applied when the caller omits that keyword. For common mutable defaults (`Array`, `Hash`, `Set`, `String`), the value is duplicated per instance (shallow). If you need deeper setup (or derived values), use the post-initialize block.

### Method name conflicts

`initialize_with` defines readers for each declared input (and `block`). If a method with the same name already exists, it will be overridden.

In Rails development/test (or when your logger level allows it), the gem logs a warning when it overrides an existing method.

### Referencing other inputs in defaults

You can’t reference one declared input from another input’s default at declaration time:

```ruby
initialize_with :user, account: user.account # user is not available here
```

Use the post-initialize block instead:

```ruby
initialize_with :user, account: nil do
  @account ||= user.account
end
```

### Inheritance and `super`

`initialize_with` generates an `initialize` method. If a subclass calls `initialize_with`, it replaces the parent initializer and **does not call `super`**. Prefer a single initializer per hierarchy, or avoid this gem for complex inheritance chains.

## Contributing

- **Source**: [teamshares/declarative_initialization](https://github.com/teamshares/declarative_initialization)
- **Code of conduct**: [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)
