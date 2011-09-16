module DataMapper
  class Property
    prefix = 'dm-appengine/properties'
    
    class_mapping = [
      ['key', [:AncestorKey, :Key]],
      ['native', [:AppEngineNative, :IMHandle, :GeoPt, :User]],
      ['string', [:AppEngineStringType, :Blob, :ByteString, :Link, :Email,
                  :Category, :PhoneNumber, :PostalAddress]],
      ['rating', [:Rating]],
      ['list', [:List]]
    ]
    
    class_mapping.each do |name, classes|
      path = "#{prefix}/#{name}"
      classes.each do |klass|
        autoload(klass, path)
      end
    end
  end
end
