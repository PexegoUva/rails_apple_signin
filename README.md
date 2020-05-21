# AppleIdToken

[![Gem Version](https://badge.fury.io/rb/apple_id_token.svg)](https://badge.fury.io/rb/apple_id_token)
[![Test Coverage](https://api.codeclimate.com/v1/badges/d7038393581f138d71da/test_coverage)](https://codeclimate.com/github/PexegoUva/rails_apple_signin/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/d7038393581f138d71da/maintainability)](https://codeclimate.com/github/PexegoUva/rails_apple_signin/maintainability)

This gem is a simple wrapper around Apple Sign In to validate provided tokens from https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens. You can also send tokens provided by official Apple library for iOS and Android applications.

We make use of JWT Ruby gem -> https://github.com/jwt/ruby-jwt to decode token provided by Apple and also it makes all the validations mentioned here -> https://developer.apple.com/documentation/sign_in_with_apple/sign_in_with_apple_rest_api/verifying_a_user to ensure integrity of provided token.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'apple_id_token'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install apple_id_token

## Usage

To make use of the gem, just call `.validate` method of `AppleIdToken::Validator`.
You need to provide token issued by Apple and also your APP_ID generated here -> https://help.apple.com/developer-account/#/devde676e696 as audience.

```ruby
validator = AppleIdToken::Validator
begin
  payload = validator.validate(token: token, aud: audience)
  user_id = payload['sub']
  email = payload['email']
rescue AppleIdToken::PublicKeysError => e
  report "Provided keys are invalid: #{e}"
rescue AppleIdToken::ValidationError => e
  report "Cannot validate: #{e}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PexegoUva/rails_apple_signin
