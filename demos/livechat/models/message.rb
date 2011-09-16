class Message
  include DataMapper::Resource

  property :id, Serial
  property :text, String, :length => 256
  property :created_at, DateTime
  property :updated_at, DateTime
  property :sequence, Integer
  property :chat_id, Integer
  property :chat_user_id, Integer
  
  belongs_to :chat
  belongs_to :chat_user

  def to_json(*args)
    {
      :userName => chat_user.username,
      :messageText => text,
      :dateTime => created_at.strftime("%Y/%m/%d %H:%M:%S %z")
    }
  end
end