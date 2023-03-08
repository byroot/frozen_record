# FrozenRecord

[![Build Status](https://secure.travis-ci.org/byroot/frozen_record.svg)](http://travis-ci.org/byroot/frozen_record)
[![Gem Version](https://badge.fury.io/rb/frozen_record.svg)](http://badge.fury.io/rb/frozen_record)

Active Record-like interface for **read only** access to static data files of reasonable size.

## Installation

Add this line to your application's Gemfile:

    gem 'frozen_record'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install frozen_record

## Models definition

Just like with Active Record, your models need to inherits from `FrozenRecord::Base`:

```ruby
class Country < FrozenRecord::Base
end
```

But you also have to specify in which directory your data files are located.
You can either do it globally

```ruby
FrozenRecord::Base.base_path = '/path/to/some/directory'
```

Or per model:
```ruby
class Country < FrozenRecord::Base
  self.base_path = '/path/to/some/directory'
end
```

You can also specify a custom backend. Backends are classes that know how to
load records from a static file. By default FrozenRecord expects an YAML file,
but this option can be changed per model:

```ruby
class Country < FrozenRecord::Base
  self.backend = FrozenRecord::Backends::Json
end
```

### Custom backends

A custom backend must implement the methods `filename` and `load` as follows:

```ruby
module MyCustomBackend
  extend self

  def filename(model_name)
    # Returns the file name as a String
  end

  def load(file_path)
    # Reads file and returns records as an Array of Hash objects
  end
end
```

## Query interface

FrozenRecord aim to replicate only modern Active Record querying interface, and only the non "string typed" ones.

e.g
```ruby
# Supported query interfaces
Country.
  where(region: 'Europe').
  where.not(language: 'English').
  order(id: :desc).
  limit(10).
  offset(2).
  pluck(:name)

# Non supported query interfaces
Country.
  where('region = "Europe" AND language != "English"').
  order('id DESC')
```

### Scopes

Basic `scope :symbol, lambda` syntax is now supported in addition to class method syntax.

```ruby
class Country
  scope :european, -> { where(continent: 'Europe' ) }

  def self.republics
    where(king: nil)
  end

  def self.part_of_nato
    where(nato: true)
  end
end

Country.european.republics.part_of_nato.order(id: :desc)
```

### Supported query methods

  - where
  - where.not
  - order
  - limit
  - offset

### Supported finder methods

  - find
  - first
  - last
  - to_a
  - exists?

### Supported calculation methods

  - count
  - pluck
  - ids
  - minimum
  - maximum
  - sum
  - average


## Indexing

Querying is implemented as a simple linear search (`O(n)`). However if you are using Frozen Record with larger datasets, or are querying
a collection repeatedly, you can define indices for faster access.

```ruby
class Country < FrozenRecord::Base
  add_index :name, unique: true
  add_index :continent
end
```

Composite index keys are not supported.

The primary key isn't indexed by default.

## Rich Types

The `attribute` method can be used to provide a custom class to convert an attribute to a richer type.
The class must implement a `load` class method that takes the raw attribute value and returns the deserialized value (similar to
[ActiveRecord serialization](https://api.rubyonrails.org/v7.0.4/classes/ActiveRecord/AttributeMethods/Serialization/ClassMethods.html#method-i-serialize)).

```ruby
class ContinentString < String
  class << self
    alias_method :load, :new
  end
end

Size = Struct.new(:length, :width, :depth) do
  def self.load(value) # value is lxwxd eg: "23x12x5"
    new(*value.split('x'))
  end
end

class Country < FrozenRecord::Base
  attribute :continent, ContinentString
  attribute :size, Size
end
```

## Limitations

Frozen Record is not meant to operate on large unindexed datasets.

To ensure that it doesn't happen by accident, you can set `FrozenRecord::Base.max_records_scan = 500` (or whatever limit makes sense to you), in your development and test environments.
This setting will cause Frozen Record to raise an error if it has to scan more than `max_records_scan` records. This property can also be set on a per model basis.

## Configuration

### Reloading

By default the YAML files are parsed once and then cached in memory. But in development you might want changes to be reflected without having to restart your application.

For such cases you can set `auto_reloading` to `true` either globally or on a model basis:

```ruby
FrozenRecord::Base.auto_reloading = true # Activate reloading for all models
Country.auto_reloading # Activate reloading for `Country` only
```

## Testing

Testing your FrozenRecord-backed models with test fixtures is made easier with:

```ruby
require 'frozen_record/test_helper'

# During test/spec setup
test_fixtures_base_path = 'alternate/fixture/path'
FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)

# During test/spec teardown
FrozenRecord::TestHelper.unload_fixtures
```

Here's a Rails-specific example:

```ruby
require "test_helper"
require 'frozen_record/test_helper'

class CountryTest < ActiveSupport::TestCase
  setup do
    test_fixtures_base_path = Rails.root.join('test/support/fixtures')
    FrozenRecord::TestHelper.load_fixture(Country, test_fixtures_base_path)
  end

  teardown do
    FrozenRecord::TestHelper.unload_fixtures
  end

  test "countries have a valid name" do
  # ...
```

## Contributors

FrozenRecord is a from scratch reimplementation of a [Shopify](https://github.com/Shopify) project from 2007 named `YamlRecord`.
So thanks to:

  - John Duff - [@jduff](https://github.com/jduff)
  - Dennis O'Connor - [@dennisoconnor](https://github.com/dennisoconnor)
  - Christopher Saunders - [@csaunders](https://github.com/csaunders)
  - Jonathan Rudenberg - [@titanous](https://github.com/titanous)
  - Jesse Storimer - [@jstorimer](https://github.com/jstorimer)
  - Cody Fauser - [@codyfauser](https://github.com/codyfauser)
  - Tobias Lütke - [@tobi](https://github.com/tobi)
