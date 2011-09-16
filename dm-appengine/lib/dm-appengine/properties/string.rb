module DataMapper
  class Property
    class AppEngineStringType < String
      def self.dump(value, property)
        if value.nil?
          nil
        else
          typecast(value)
        end
      end
      
      def self.load(value, property)
        value
      end
      
      def typecast_to_primitive(value)
        primitive.new(value) if value
      end
      
      #Overriding the default string length.
      def initialize(model, name, options = {}, type = nil)
        super
        @length = @options.fetch(:length, self.class.length)
      end
      
      def self.inherited klass
        klass.extend ClassMethods
      end
      
      module ClassMethods
        attr_accessor :length
      end
    end
    
    class Blob < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::Blob
      self.length = 1024 * 1024
    end
    
    class ByteString < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::ByteString
      self.length = 500
    end
    
    class Link < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::Link
      self.length = 2038
    end
    
    class Email < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::Email
      self.length = 500
    end
    
    class Category < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::Category
      self.length = 500
    end
    
    class PhoneNumber < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::PhoneNumber
      self.length = 500
    end
    
    class PostalAddress < AppEngineStringType
      accept_options :required
      primitive AppEngine::Datastore::PostalAddress
      self.length = 500
    end
  end
end
