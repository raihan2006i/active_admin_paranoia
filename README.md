# active_admin_paranoia
This gem extends ActiveAdmin so that batch restore and batch archive actions will be available in resource index page. Also 'All' and 'Archived' scope will be available for resource index page. 'All' scope will show non archived resources and 'Archived' scope will show deleted or archived resources.

# Installation
This gem assumes that you have already configured [paranoia](https://github.com/radar/paranoia) for you desire resource. Add this line to your application's Gemfile:

```ruby
gem "active_admin_paranoia" , '~> 1.0.6'

```

And then execute:

    $ bundle

# Usages

```ruby
ActiveAdmin.register Post do
  active_admin_paranoia
end
```
