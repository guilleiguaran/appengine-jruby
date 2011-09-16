module DataMapper
  class Property
    class List < Object
      primitive ::Object
      
      def dump(value)
        value
      end
      
      def load(value)
        value
      end
    end
  end
end