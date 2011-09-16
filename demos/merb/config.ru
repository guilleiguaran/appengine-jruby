require 'appengine-rack'
 
AppEngine::Rack.configure_app(
    :application => 'application-id',
    :version => 1)
 
require 'rubygems'
require 'merb-core'
Merb::Config.setup(
    :merb_root => File.dirname(__FILE__),
    :environment => AppEngine::Rack.environment)
 
Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

run Merb::Rack::Application.new
