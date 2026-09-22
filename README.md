# RBS Enum

Use RBS literal unions as Ruby arrays. Keep enum values in your signatures and reuse them in forms, validations, and component options without maintaining the same list twice.

## Installation

Add the gem to your Gemfile and run `bundle install`:

```ruby
gem "rbs_enum"
```

Requires Ruby 3.1 or later. Rails is optional.

## Usage

Define a literal union in a signature file:

```rbs
# sig/status.rbs
type status = :draft | :published
```

In Rails, signatures are read from your application's `sig/` directory automatically:

```ruby
RbsEnum.values("status") # => [:draft, :published]
```

Pass the alias name as written after `type`. Outside Rails, require the gem and configure the signature directory before looking up values:

```ruby
require "rbs_enum"

RbsEnum.configure do |config|
  config.sig_root = File.expand_path("sig", __dir__)
end

RbsEnum.values("status") # => [:draft, :published]
```

String unions return strings and can supply values for an Active Record validation:

```rbs
# sig/order.rbs
type order_status = "draft" | "submitted" | "fulfilled"
```

```ruby
class Order < ApplicationRecord
  validates :status, inclusion: { in: RbsEnum.values("order_status") }
end
```

## Configuration

Set application defaults with `configure`. In Rails, place this in an initializer:

```ruby
# config/initializers/rbs_enum.rb
RbsEnum.configure do |config|
  config.sig_root = Rails.root.join("signatures")
  config.strict = true
end
```

- `sig_root`: The directory searched recursively for `.rbs` files. Defaults to `Rails.root.join("sig")` in Rails; must be supplied outside Rails.
- `strict`: Whether to raise `RbsEnum::UnknownType` when no literal values are found. Defaults to `false`, which returns `[]` instead.

Override either setting for an individual lookup:

```ruby
RbsEnum.values("status", sig_root: "/path/to/signatures", strict: true)
RbsEnum.values("maybe_missing", strict: false) # => []
```

Strict mode detects lookups with no results; it does not validate RBS syntax or ensure the entire alias is supported.

## Supported types and limitations

RBS Enum supports flat unions of symbol or string literals, including unions spread across multiple lines. Symbol unions return symbols, string unions return strings, and mixed symbol/string unions return strings. Comments are ignored while `#` characters inside quoted values are preserved.

The gem scans signature files with regular expressions and has no dependency on the `rbs` gem. It does not build a type model or resolve references to other aliases. Generics, records, interfaces, and nested type expressions are outside its supported syntax.

Unsupported expressions are not reliably rejected: the scanner can extract literals from part of an expression. For example:

```rbs
type partial_status = :draft | String
```

```ruby
RbsEnum.values("partial_status", strict: true) # => [:draft]
```

Use aliases made entirely of supported literals when the returned array needs to represent every allowed value.

## Caching and Rails reloading

Results are cached by signature directory and alias name. After changing signature files in a running process, clear the cache with:

```ruby
RbsEnum.clear_cache!
```

This preserves your configuration. Rails clears the cache automatically during application reloading. Values already assigned to constants or passed to validations are refreshed only when that application code runs again. Strict lookups that raise do not add a cache entry.

## Development

Clone the repo, then run `bundle install` and `bundle exec rspec`. Include tests with behavior changes.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/NicolasJJensen/rbs_enum).

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
