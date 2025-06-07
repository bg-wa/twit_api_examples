# TWiT API Examples

This repository contains example code for interacting with the TWiT.tv API in various programming languages.

## Getting Started

1. **Set up your API credentials:**
   - Copy `examples/credentials.yml.sample` to `examples/credentials.yml`
   - Edit `examples/credentials.yml` and add your TWiT API credentials from 3Scale

2. **Choose your preferred language:**
   - Ruby examples are in `examples/ruby/`
   - Additional language examples will be added in their respective directories

## API Documentation

The TWiT API documentation is available in the `documentation` directory:
- `documentation/twittv.apib` - API Blueprint format documentation

## API Authentication

API Authentication is provided by 3Scale at https://twit-tv.3scale.net. You'll need to register for an account and apply for access to the TWiT.tv API via an Application plan.

## Available Examples

### Ruby
- Basic connection test
- Comprehensive API client with support for multiple endpoints

### Other Languages
- Coming soon

## Security Note

The `credentials.yml` file is ignored by git to prevent accidentally committing your API keys. Always keep your API credentials secure and never commit them to version control.
