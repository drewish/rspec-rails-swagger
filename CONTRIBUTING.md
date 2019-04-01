# Contributing

## Running tests

The `scripts/make_site.sh` script will create a test site for a specific version of
Rails:
```
export RAILS_VERSION=4.2.0
scripts/make_site.sh
```

Once the test site is created you can run the tests:
```
scripts/run_tests.sh
```
