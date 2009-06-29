require 'libxml'

class LibXML::XML::Parser
  class << self
    def parse(string)
      string(string).parse
    end
  end
end