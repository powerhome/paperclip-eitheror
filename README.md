# Paperclip::Eitheror
[![Build Status](https://travis-ci.org/powerhome/paperclip-eitheror.svg?branch=master)](https://travis-ci.org/powerhome/paperclip-eitheror)

A [Paperclip](https://github.com/thoughtbot/paperclip/) Storage which allows you to use a secondary (called 'or') storage as a fallback.
The purpose of this gem is to help us while a migrating our assets and uploads to a different place.

Dependency versions are locked to the current versions we have running.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paperclip-eitheror'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperclip-eitheror

## Usage

Given you have the gem installed and a some model, you need to configure your attachment with `storage: :eitheror`, and configurations for both the primary (`either`) and the fallback (`or`) storages,

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  either: {
    storage: :fog
  },
  or: {
    storage: :filesystem
  }
}
```

You can use specific configuration by passing them on one of the storages config. For instance:

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  either: {
    storage: :fog,
    path: 'some_fog_path/:style/:filename'
  },
  or: {
    storage: :filesystem,
    path: 'some_local_path/:class/:attachment/:style/:filename'
  }
}
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/paperclip-eitheror. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
