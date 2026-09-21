# RBS Enum

Use the allowed values from an RBS type alias in your Ruby code. This avoids maintaining the same list twice when you need it for a form, validation, or component options.

## What it actually does

RBS Enum does **not** depend on the `rbs` gem and does **not** parse RBS. It scans `sig/**/*.rbs` with a regular expression, finds the line that declares the alias, and reads flat unions of symbol or string literals out of it.

That means:

- A flat union of literals works: `type status = :draft | :sent`.
- Anything else returns an empty array: references to other aliases, generics, record types, interfaces, nested unions, and unions of non-literal types.
- A mixed union of symbols and strings is returned as **strings**. The gem does not return a mixed array.
- Comments after the union are stripped, and the scan stops at the next declaration.

Use `strict: true` (below) if you would rather see an error than an empty array.

## Installation

Add the gem to your Rails application's Gemfile and run `bundle install`:

```ruby
gem "rbs_enum"
```

Requires Ruby 3.1+. In Rails, the gem reads signatures from `sig/` automatically.

## Usage

RBS can describe a set of allowed values, but that list is not directly available to Ruby at runtime. Without the gem, you might repeat it:

```rbs
# sig/button.rbs
type button_color = :primary | :warning | :danger
```

```ruby
# app/components/button.rb
class Button
  COLORS = %i[primary warning danger]
end
```

With RBS Enum, keep the signature and replace the duplicated Ruby list:

```ruby
# app/components/button.rb
class Button
  COLORS = RbsEnum.values("button_color")
end
```

Now `Button::COLORS` returns `[:primary, :warning, :danger]`. Use it wherever the application needs that list:

```erb
<%= form.select :color, Button::COLORS.map { |color| [color.to_s.humanize, color] } %>
```

String unions work too:

```rbs
# sig/order.rbs
type order_status = "draft" | "submitted" | "fulfilled"
```

```ruby
# app/models/order.rb
class Order < ApplicationRecord
  validates :status, inclusion: { in: RbsEnum.values("order_status") }
end
```

Pass the alias name as written after `type`.

## Strict lookups

By default an alias the gem cannot read returns `[]`. That is quiet, and a typo in the alias name looks the same as an empty enum. Pass `strict: true` to raise `RbsEnum::UnknownType` instead:

```ruby
RbsEnum.values("button_color", strict: true)
```

Set the default for the whole application through `configure`:

```ruby
RbsEnum.configure do |config|
  config.strict = true
end
```

A per-call `strict:` argument wins over the configured default, so `RbsEnum.values("maybe_missing", strict: false)` still returns `[]`. A strict lookup that raises is not cached.

## Optional configuration

If your signatures live outside `sig/`, configure their location:

```ruby
RbsEnum.configure do |config|
  config.sig_root = Rails.root.join("signatures")
end
```

For a single lookup elsewhere:

```ruby
RbsEnum.values("button_color", sig_root: "/path/to/signatures")
```

Outside Rails, set `sig_root` before reading values.

Results are cached per signature root and alias name. Call `RbsEnum.clear_cache!` to drop that cache after changing signature files in a running process. It clears the cache only and leaves `sig_root` and `strict` alone. Rails calls it on each reload.

## Development

Clone the repo, then run `bundle install` and `bundle exec rspec`. Include tests with behavior changes.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/NicolasJJensen/rbs_enum.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
