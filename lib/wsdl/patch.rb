puts "Patching WSDL"
module WSDL
  class Import < Info
    def parse_attr(attr, value)
      case attr
      when NamespaceAttrName
        @namespace = value.source
        # if @content
        #   @content.targetnamespace = @namespace
        # end
        @namespace
      when LocationAttrName
        @location = URI.parse(value.source)
        if @location.relative? and !parent.location.nil? and
            !parent.location.relative?
          @location = parent.location + @location
        end
        if root.importedschema.key?(@location)
          @content = root.importedschema[@location]
        else
          root.importedschema[@location] = nil      # placeholder
          @content = import(@location)
          if @content.is_a?(Definitions)
            @content.root = root
            if @namespace
              @content.targetnamespace = @namespace
            end
          end
          root.importedschema[@location] = @content
        end
        @location
      else
        nil
      end
    end
  end
end