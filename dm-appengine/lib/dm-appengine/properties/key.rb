module DataMapper
  class Property
    class Key < Object
      primitive AppEngine::Datastore::Key
      include PassThroughLoadDump
      
      def dump(value)
        typecast(value)
      end
      def load(value)
        value
      end
      
      def typecast(value)
        if value.nil?
          value
        else
          super
        end
      end
      
      def self.typecast_to_primitive(property, value)
        case value
          when ::AppEngine::Datastore::Key, ::NilClass
            value
          when ::Integer, ::String
            AppEngine::Datastore::Key.from_path(kind(property), value)
          when ::Symbol
            AppEngine::Datastore::Key.from_path(kind(property), value.to_s)
          when ::Hash
            parent = self.typecast_to_primitive(property, value[:parent])
            id = value[:id]
            name = value[:name]
            if id
              id_or_name = id.to_i
            elsif name
              id_or_name = name.to_s
            end
            if parent
              id_or_name ||= 0
              parent.getChild(kind(property), id_or_name)
            else
              self.typecast_to_primitive(property, property.typecast(id_or_name))
            end
          else
            raise ArgumentError, "Unsupported key value #{value.inspect} (a #{value.class})"
        end
      end
      
      def self.kind(property)
        property.model.repository.adapter.kind(property.model)
      end
      
      def typecast_to_primitive(value)
        self.class.typecast_to_primitive(self, value)
      end
      
      accept_options :serial
      
      # THIS IS A HACK.
      # I'm not sure the best way to do this. The key is not technically required at
      # object creation time, but should be seen as required after that.
      def initialize(model, name, options = {}, type = nil)
        super
        @serial = options.fetch(:serial, @key)
      end
      
      VALID_KEY_OPTS = Set.new([:id, :name, :parent]).freeze
      
      def valid?(value, negated = false)
        if value.kind_of? Hash
          return false unless value.keys.all?{|k| VALID_KEY_OPTS.include? k}
          !(value[:id] && value[:name])
        else
          super
        end
      end
    end
    
    # Hack to allow a property defined as AppEngine::Datastore::Key to work.
    # This is needed for associations -- child_key tries to define it as
    # the primitive of the parent key type. It then takes that type name and
    # tries to resolve it in DM::Property, so we catch it here.
    module Java
      module ComGoogleAppengineApiDatastore
      end
    end
    Java::ComGoogleAppengineApiDatastore::Key = Key
    
    class AncestorKey < Key; end
  end
end
