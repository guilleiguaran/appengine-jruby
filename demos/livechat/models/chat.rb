class Chat
  include DataMapper::Resource


  property :id, Serial
  property :entity_type, String
  property :entity_id, Integer
  property :created_at, DateTime
  property :updated_at, DateTime

  has n, :messages

  has n, :chat_users
  
end