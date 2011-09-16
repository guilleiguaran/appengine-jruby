require 'appengine-rack'
require 'guestbook'

AppEngine::Rack.configure_app(
    :application => 'application-id',
    :precompilation_enabled => true,
    :version => 1)

run Sinatra::Application
