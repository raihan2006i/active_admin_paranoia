# active_admin_paranoia
This gem extends ActiveAdmin so that your index page's table rows will have "Restore" and "Delete permanently" actions for paranoia enabled resource

# Installation

Add this line to your application's Gemfile:

```ruby
gem "active_admin_paranoia" , '~> 1.0.0'

```

And then execute:

    $ bundle

# Usages

```ruby
ActiveAdmin.register Post do
  active_admin_paranoia
end
```
