class Counter

  include DataMapper::Resource

  property :id, Serial
  property :name, String
  property :sequence, Integer, :default => 0

  def self.get_sequence(name)
    counter = find_or_create(:name => name)
    counter.sequence +=1
    counter.save
    counter.sequence
  end
end