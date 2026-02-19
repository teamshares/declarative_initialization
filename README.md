# Declarative Initialization

Stop writing boilerplate `def initialize` methods. Define your class's inputs declaratively and let Ruby do the rest.

`DeclarativeInitialization` provides a simple, zero-dependency way to define initialization logic for keyword-based classes. It handles assignment, validation, and reader generation so you can focus on your business logic.

## What it does

*   **Generates `initialize`**: Automatically assigns keyword arguments to instance variables.
*   **Creates `attr_reader`s**: Exposes arguments as private readers (by default).
*   **Validates inputs**: Raises helpful errors for missing or unknown keyword arguments.
*   **Handles defaults**: Supports optional arguments with default values.
*   **Captures blocks**: Automatically captures any block passed to `.new` as `@block`.

## When to use it

Perfect for:
*   **Service Objects / Command Objects**: Where you pass in dependencies and arguments to execute a single action.
*   **Value Objects**: Where you need immutable state initialized once.
*   **ViewComponents**: Where you accept a set of parameters to render a UI component.
*   **Configuration Objects**: Where you have many optional flags with defaults.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'declarative_initialization'
```

And then execute:

```bash
bundle install
```

## Usage

### Basic Usage

Include the module and use `initialize_with` to define your required arguments.

```ruby
class UserGreeter
  include DeclarativeInitialization

  # :user is required
  initialize_with :user

  def call
    "Hello, #{user.name}!"
  end
end

greeter = UserGreeter.new(user: current_user)
greeter.call # => "Hello, Alice!"

# Raises ArgumentError: Missing keyword argument(s): user
UserGreeter.new
```

### With Defaults

You can mix required arguments (symbols) and optional arguments (hash).

```ruby
class SearchService
  include DeclarativeInitialization

  # :query is required
  # :limit defaults to 10
  # :sort defaults to :desc
  initialize_with :query, limit: 10, sort: :desc

  def perform
    results = perform_search(query)
    results = results.take(limit)
    sort == :desc ? results.reverse : results
  end
end

SearchService.new(query: "ruby")             # limit=10, sort=:desc
SearchService.new(query: "ruby", limit: 50)  # limit=50, sort=:desc
```

### Custom Logic (Post-Initialize)

If you need to perform logic after assignment (like computing derived values), pass a block to `initialize_with`.

```ruby
class Rectangle
  include DeclarativeInitialization

  initialize_with :width, :height do
    # This runs after @width and @height are set
    @area = @width * @height
    
    if @width <= 0 || @height <= 0
      raise ArgumentError, "Dimensions must be positive"
    end
  end

  attr_reader :area
end
```

### Handling Blocks

If a block is passed to `.new`, it is automatically captured as `@block` and exposed via a `block` reader.

```ruby
class Wrapper
  include DeclarativeInitialization

  initialize_with :tag

  def render
    "<#{tag}>#{block.call}</#{tag}>"
  end
end

Wrapper.new(tag: "div") { "Content" }.render 
# => "<div>Content</div>"
```

## Edge Cases & Gotchas

### Method Conflicts
`DeclarativeInitialization` creates `attr_reader` methods for all arguments.
*   **If a method already exists:** It will be **overridden** to ensure the initializer works correctly.
*   **Warning:** In development/test environments, it will log a warning if it overrides an existing method (unless that method was defined by an ancestor's `initialize_with`).

### Referencing Other Defaults
You cannot reference one argument in the default value of another within the declaration itself.

**❌ Doesn't work:**
```ruby
initialize_with :user, account: user.account # Error: user undefined
```

**✅ Workaround:**
Use the post-initialize block or lazy initialization.
```ruby
initialize_with :user, account: nil do
  @account ||= user.account
end
```

### Inheritance and `super`
Because `initialize` is generated dynamically:
1.  **Calling `super`**: You cannot easily call `super` from a custom `initialize` if you mix `DeclarativeInitialization` with manual `def initialize`. It's best to stick to `initialize_with` across the hierarchy or use manual initialization for complex inheritance chains.
2.  **Overriding**: If a subclass uses `initialize_with`, it completely replaces the parent's `initialize` method.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/teamshares/declarative_initialization. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/teamshares/declarative_initialization/blob/main/CODE_OF_CONDUCT.md).
