# Unreleased

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
