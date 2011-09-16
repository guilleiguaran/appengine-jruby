require 'appengine-rack'

ENV['RAILS_ENV'] = AppEngine::Rack.environment

#deferred_dispatcher = AppEngine::Rack::DeferredDispatcher.new(
#    :require => File.expand_path('../config/environment', __FILE__),
#    :dispatch => 'ActionController::Dispatcher')
#
#map '/' do
#  run deferred_dispatcher
#end

require 'config/environment'
run ActionController::Dispatcher.new
