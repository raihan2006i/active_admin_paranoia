require 'active_admin'
require 'active_admin_paranoia/version'
require 'active_admin_paranoia/engine'
require 'active_admin_paranoia/dsl'
require 'active_admin_paranoia/authorization'
::ActiveAdmin::DSL.send(:include, ActiveAdminParanoia::DSL)
