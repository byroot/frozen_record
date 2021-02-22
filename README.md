# FrozenRecord

[![Build Status](https://secure.travis-ci.org/byroot/frozen_record.svg)](http://travis-ci.org/byroot/frozen_record)
[![Code Climate](https://codeclimate.com/github/byroot/frozen_record.svg)](https://codeclimate.com/github/byroot/frozen_record)
[![Coverage Status](https://coveralls.io/repos/byroot/frozen_record/badge.svg)](https://coveralls.io/r/byroot/frozen_record)
[![Gem Version](https://badge.fury.io/rb/frozen_record.svg)](http://badge.fury.io/rb/frozen_record)

ActiveRecord-like interface for **read only** access to static data files.

## Installation

Add this line to your application's Gemfile:

    gem 'frozen_record'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install frozen_record

## Models definition

Just like with ActiveRecord, your models need to inherits from `FrozenRecord::Base`:

```ruby
class Country < FrozenRecord::Base
end
```

But you also have to specify in which directory your data files are located.
You can either do it globaly

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

FrozenRecord aim to replicate only modern ActiveRecord querying interface, and only the non "string typed" ones.

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
a collection repetedly, you can define indices for faster access.

```ruby
class Country < FrozenRecord::Base
  add_index :name, unique: true
  add_index :continent
end
```

Composite index keys are not supported.

The primary key isn't indexed by default.

## Associations

ActiveRecord models can be associated with FrozenRecord models by including the `FrozenRecord::Reflection` module.

Two types of associations are supported:
- `belongs_to_frozen`
- `belongs_to_many_frozen`

### The belongs_to_frozen Association

A `belongs_to_frozen` association is similar to `ActiveRecord.belongs_to`. For example, if your application includes authors and books, where authors are Frozen Records, you'd declare the book model this way:

```ruby
class Book < ApplicationRecord
  include FrozenRecord::Reflection

  belongs_to_frozen :author
end
```

By default, the Book model would be expected to respond to `#author_id` with a value that matches an Author record's `#id` attribute.

The `belongs_to_frozen` association supports these options:

- `:class_name`
- `:foreign_key`
- `:primary_key`

#### :class_name

If the name of the FrozenRecord model cannot be derived from the association name, you can use the :class_name option to supply the model name.

#### :foreign_key

By convention, it is assumed that the column used to hold the foreign key on this model is the name of the association with the suffix _id added. The :foreign_key option lets you set the name of the foreign key directly.

#### :primary_key

By convention, it is assumed that the id attribute is used to hold the primary key of frozen records. The :primary_key option allows you to specify a different attribute.

### The belongs_to_many_frozen Association

A `belongs_to_many_frozen` association is like a `belongs_to_frozen` association, but for a collection. For example, if your application includes genres and books, where genres are Frozen Records, you'd declare the book model this way:

```ruby
class Book < ApplicationRecord
  include FrozenRecord::Reflection

  belongs_to_many_frozen :genres
end
```

By default, the Book model would be expected to respond to `#genre_ids` with an array of values that match Author records' `#id` attribute. If your database supports arrays (e.g PostgreSQL), you could accomplish this with an array column named `genre_ids`.

The `belongs_to_many_frozen` association supports the same options as `belongs_to_frozen`.

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
    test_fixtures_base_path = Rails.root.join(%w(test support fixtures))
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
