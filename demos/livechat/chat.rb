require 'sinatra'
require 'json'
require 'dm-core'
#require 'dm-validations'
require 'dm-timestamps'
require 'dm-serializer'
require 'dm-ar-finders'
require 'haml'

# Configure DataMapper to use the App Engine datastore 
DataMapper.setup(:default, "appengine://auto")

require 'models/chat'
require 'models/chat_user'
require 'models/message'
require 'models/counter'

use Rack::Session::Cookie

set :haml, :layout => :'layouts/default'




helpers do
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end

  include Rack::Utils
  alias_method :h, :escape_html
end

get '/chat/:id/users' do
  @chat_users = ChatUser.current(params[:id].to_i)

  content_type 'json'

  @chat_users.collect{|chat_user| {:id => chat_user.id, :userName => chat_user.username} }.to_json
end

get '/chat/:id/messages' do
  messages = Message.all(:chat_id => params[:id].to_i, :sequence.gte => params[:last_message_sequence].to_i, :order => [:sequence.desc])
  messages.reject!{|i| i.id.to_i == params[:last_message_id].to_i}
  last_message = messages.first unless messages.empty?
  content_type 'json'
  json_response = {:messages => messages}
  if(last_message)
    json_response[:lastMessageId] = last_message.id
    json_response[:lastMessageSequence] = last_message.sequence
  end
  json_response.to_json
end

post '/chat/:id/ping' do
  chat_user = ChatUser.get(params[:chat_user_id].to_i)
  chat_user.last_seen_at_in_sec = Time.now
  content_type 'json'

  if(chat_user.save)
    {:ping => 'GOOD'}.to_json
  else
    {:ping => 'BAD'}.to_json
  end

end

get '/chat/:type/:id' do
  @chat = Chat.find_or_create(:entity_type => params[:type], :entity_id => params[:id].to_i)
  @chat_users = ChatUser.current(@chat.id)
  @chat_messages = @chat.messages(:limit => 10, :order => [:sequence.desc])
  @last_chat_message = @chat_messages.first
  if(@last_chat_message)
    @last_chat_message_id = @last_chat_message.id
    @last_chat_message_sequence = @last_chat_message.sequence
  else
    @last_chat_message_id = 'null'
    @last_chat_message_sequence = 'null'
  end
  haml :'chats/index' 
end





post '/chat/:id' do
  chat_user = ChatUser.find_or_create(:username => params[:username], :chat_id => params[:id].to_i, :ip_address => @env['REMOTE_ADDR'])
  message = Message.create(:text => params[:message], :chat_id => params[:id].to_i, :chat_user_id => chat_user.id, :sequence => Counter.get_sequence('Message'))
  content_type 'json'
  {:chatUserId => chat_user.id}.to_json
end
