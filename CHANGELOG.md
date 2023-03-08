# Unreleased

# v0.27.0

- Allow to define some richer attibute types, somewhat akin to Active Record `serialize` attributes. See the README for more information.
- Fix `Model.find_by` fastpath raising an error when called before records are loaded.

# v026.2

- Properly load records when entiring the single attribute lookup fastpath.

# v0.26.1

- Optimized single attribute lookup.

# v0.26.0

- Drop dependency on `dedup` gem.

# v0.25.5

- `FrozenRecord::Base#==` now returns `false` if the primary key is `nil` (to match the `ActiveRecord::Base` implementation)

# v0.25.4

- Minor Ruby 3.2 compatiblity fix (regarding `ruby2_keywords`).

# v0.25.3

- Also disable max_records_scan when loading `Compact` records.

# v0.25.2

- Fix FrozenRecord.ignore_max_records_scan not applying

# v0.25.1

- More reliable way to disable max_records_scan checks when loading records.

# v0.25.0

- Disable max_records_scan checks when loading records.
- Add `FrozenRecord::Base.with_max_record_scan` for more easily allowing larger amount in specific tests.

# v0.24.1

- Fix index selection not applying some restrictions.

# v0.24.0 (yanked)

- Improve index selection and combinaison. Should significantly help with performance in some cases.
- Implement `max_records_scan` to reject slow queries.
- Only load `Railtie` integration if `Rails::Railtie` is defined
- Allow granular fixture unloading
- Fix a bug affecting older bootsnap versions

# v0.23.0

NO DATA
