## [Unreleased]

- **BREAKING:** Override by default when a method already exists
  - Previously, if a method `#foo` existed (same class or ancestor), we skipped defining the reader and warned. Users had to use `@foo` to access the init-arg.
  - Now, we **always define the reader**, overriding any existing method so `foo` consistently returns the init-arg value.
  - If you rely on an existing method (e.g. ViewComponent's `renders_one :title`), use a different init-arg name (e.g. `title_content: nil`).
- Optional override warning in development/test (Rails) or when logger level is DEBUG
- No longer warns on Rails reload when the method was defined by us
- No longer warns when subclass re-declares an attribute from parent's `initialize_with`

## [0.1.1] - 2025-05-02
- Refactor internals
- [BUGFIX] Only trigger `attr_reader` creation on initial class load (vs on every call to `#new`)


## [0.1.0] - 2025-03-05
- Initial release
