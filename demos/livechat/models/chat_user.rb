class ChatUser
  USER_CHAT_TIMEOUT = 60
  include DataMapper::Resource


  property :id, Serial
  property :username, String, :length => 32
  property :ip_address, String, :length => 15 #15 chars for xxx.xxx.xxx.xxx for ip4
  property :created_at, DateTime
  property :updated_at, DateTime
  property :last_seen_at, DateTime, :default => lambda { |r, p| DateTime.now }
  property :last_seen_at_in_sec, Integer, :default => lambda { |r, p| Time.now.to_i }

  property :chat_id, Integer
  belongs_to :chat

  def self.current(chat_id)
    self::all(:chat_id => chat_id, :last_seen_at_in_sec.gte => (Time.now.to_i - self::USER_CHAT_TIMEOUT)).sort{|a, b| a.username <=> b.username}
  end
end