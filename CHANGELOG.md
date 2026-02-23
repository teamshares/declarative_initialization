## [Unreleased]

* N/A

## [0.2.1] - 2026-02-23

### Fixed
- Avoid `ArgumentError: comparison of Symbol with 0 failed` when `Rails.logger` is wrapped by SemanticLogger (or any logger whose `level` is not an integer). Override warnings now only compare level when it is an integer.

## [0.2.0] - 2026-02-19

### Changed
- `initialize_with` readers are now always defined, even if a method with the same name already exists. This makes `foo` consistently return the init-arg value.

### Breaking
- Previously, if a method `#foo` existed (on the class or an ancestor), the gem skipped defining the reader and logged a warning; callers had to use `@foo` to access the init-arg. Now the reader is defined and overrides the existing method.

### Added
- Optional override warnings in Rails development/test, or when logger level is `DEBUG`.

### Fixed
- No warning on Rails reload when the existing method was originally defined by this gem.
- No warning when a subclass re-declares an attribute already declared by an ancestor’s `initialize_with`.
- Duplicate common mutable default values (`Array`, `Hash`, `Set`, `String`) per instance when the caller omits that keyword, preventing accidental cross-instance mutation. Copy is shallow; caller-provided values are not duplicated.


## [0.1.1] - 2025-05-02

### Changed
- Refactor internals.

### Fixed
- Only define `attr_reader`s on initial class setup (avoid re-defining on each call to `.new`).

## [0.1.0] - 2025-03-05

### Added
- Initial release.
