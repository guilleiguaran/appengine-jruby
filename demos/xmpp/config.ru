require 'rubygems'
require 'appengine-rack'
require 'appengine-apis/xmpp'
require 'stringio'

AppEngine::Rack.configure_app(:application => 'jruby-xmpp', :version => 1)
AppEngine::Rack.app.inbound_services << :xmpp_message

map "/_ah/xmpp" do
  run lambda {|env|
    data = env['rack.input'].read
    env['CONTENT_LENGTH'] = data.length
    env['rack.input'] = StringIO.new(data)
    request = Rack::Request.new(env)
    message = AppEngine::XMPP::Message.new(request)
    message.reply(message.body)
    [200, {}, 'ok']
  }
end

map "/" do
  run lambda {[200, {}, 'hello']}
end