module DataMapper
  class Property
    class Rating < Integer
      def self.dump(value, property)
        AppEngine::Datastore::Rating.new(typecast(value)) if value
      end
      
      def self.load(value, property)
        value.rating if value
      end
    end
  end
end