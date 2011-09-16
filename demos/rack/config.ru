require 'appengine-rack'

AppEngine::Rack.configure_app(
    :application => "application-id",
    :version => 1 )

run lambda { Rack::Response.new("Hello World!").finish }
