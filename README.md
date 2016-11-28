# Paperclip::Eitheror
[![Build Status](https://travis-ci.org/powerhome/paperclip-eitheror.svg?branch=master)](https://travis-ci.org/powerhome/paperclip-eitheror)

A [Paperclip](https://github.com/thoughtbot/paperclip/) Storage which supports a secondary (called 'or') storage as a fallback while using the primary one (called 'either').

The purpose of this gem is to help us while migrating our assets to a different place, a better place <3

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

Given you have the gem installed and some model, you need to configure your attachment with `storage: :eitheror`, and set up the primary (`either`) and the secondary/fallback (`or`) storages:

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
    path: ':attachment/:id/:style/:filename',
    url: ':attachment/:id/:style/:filename'
  },
  or: {
    storage: :filesystem,
    path: ':rails_root/public/attachments/:class/:attachment/:style/:filename'
  }
}
```

The configuration for each storage inherits whatever attributes are defined at the configuration top level config, and existing attributes may be overridden with storage specific values. For example:

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  url: '/api/v1/attachments/:attachment/:id/:style',
  path: ':rails_root/public/attachments/:class/:attachment/:style/:filename',
  either: {
    storage: :fog,
    path: ':attachment/:id/:style/:filename',
    url: ':attachment/:id/:style/:filename'
  },
  or: {
    storage: :filesystem,
  }
}
```

In the example above, the storage **or** will inherit the attributes `path` and `url` from the base configuration, while `either` will provide its own `path` and `url` attributes. The following configuration is equivalent:

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  either: {
    storage: :fog,
    path: ':attachment/:id/:style/:filename',
    url: ':attachment/:id/:style/:filename'
  },
  or: {
    storage: :filesystem,
    url: '/api/v1/attachments/:attachment/:id/:style',
    path: ':rails_root/public/attachments/:class/:attachment/:style/:filename',
  }
}
```

That is particularly useful when globally configuring `paparclip-eitheror`.

## Global Configuration

On large codebases it might become very tedious and error prone to chase down all paperclip usages and adapt their configuration to use `paperclip-eitheror`. An alternative is to configure `paperclip` default options to use `paperclip-eitheror` as the default storage.

```ruby
# config/initializers/paperclip.rb

Paperclip::Attachment.default_options[:storage] = :eitheror
Paperclip::Attachment.default_options[:either] = {
  storage: :fog,
  path: ':attachment/:id/:style/:filename',
  url: ':attachment/:id/:style/:filename',
}

Paperclip::Attachment.default_options[:or] = {
  storage: :filesystem,
}
```

Since storages inherit configuration from the base config, you would not have to change any of your existing models and in this case the **or** storage would inherit the configuration on your models acting as your existing storage.

In case you need a particular model to **NOT** be affected by the global configuration, you can explicitly define the storage type you want the model to use as part of its `has_attached_file` options:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar, storage: :filesystem
end
```

# Method aliasing/overriding

Different storages provide different ways of accessing attachments.
For instance, when using `:fog` storage, you have access to methods which only make sense to that particular storage.
Or when you're migrating your assets from a `:filesystem` storage to a `:fog` storage, you might not want to go after every reference to `attachment.url` in your code in order to change it to `attachment.public_url`.

`paperclip-eitheror` gives you the ability to provide an `:alias` key, which then will allow you to tell it how to behave when such scenario happens.

For instance:

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  either: {
    storage: :fog,
    alias: {
      url: :public_url
    }
  },
  or: {
    storage: :filesystem,
  }
}
```

Int he example above we're telling `paperclip-eitheror` that whenever `avatar.url` is called, the `:fog` storage will delegate it to `attachment.public_url`. Mapping `fog.url` to `fog.public_url` seems like a very straight-forward mapping.

Not always mapping from one method to another is going to be that simple, you can write you own overrides by mapping a method to a `lambda`, like so:

```ruby
has_attached_file :avatar, {
  storage: :eitheror,
  either: {
    storage: :fog,
    alias: {
      url: ->(either_storage, or_storage, attachment, *args) do
        puts "Look, I can do whatever I want"
      end
    }
  },
  or: {
    storage: :filesystem,
  }
}
```

The `lambda` will receive as parameters both storages (**either** and **or**), the attachment instance and any other arguments given when the method was called.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/powerhome/paperclip-eitheror. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
