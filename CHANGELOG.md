## [Unreleased]

- Improved "method already exists" warnings:
  - No longer warns on Rails reload when the method was defined by us
  - No longer warns when subclass re-declares an attribute from parent's `initialize_with`
  - Now warns when an inherited user-defined method conflicts (previously skipped silently)
  - Warning messages now include the class name where the conflicting method is defined
  - Warning messages suggest using `@attr` as a workaround

## [0.1.1] - 2025-05-02
- Refactor internals
- [BUGFIX] Only trigger `attr_reader` creation on initial class load (vs on every call to `#new`)


## [0.1.0] - 2025-03-05
- Initial release
