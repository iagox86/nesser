# Encoding: ASCII-8BIT
##
# question.rb
# Created June 21, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# This defines a DNS question. Typically, a single question is sent in both
# incoming and outgoing packets. Most implementations can't handle any other
# situation.
##
module Nesser
  class Question
    attr_reader :name, :type, :cls

    ##
    # Create a question.
    #
    # The name is a typical dotted name, like "google.com". The type and cls
    # are DNS-specific values that can be found in constants.rb.
    ##
    def initialize(name:, type:, cls:)
      @name  = name
      @type  = type
      @cls  = cls
    end

    ##
    # Parse a question from a DNS packet.
    ##
    def self.unpack(unpacker)
      name = unpacker.unpack_name()
      type, cls = unpacker.unpack("nn")

      return self.new(name: name, type: type, cls: cls)
    end

    ##
    # Serialize the question.
    ##
    def pack(packer)
      packer.pack_name(@name)
      packer.pack('nn', type, cls)
    end

    def to_s()
      return '%s [%s %s]' % [
        @name,
        TYPES[@type] || '<0x%04x?>' % @type,
        CLSES[@cls]  || '<0x%04x?>' % @cls,
      ]
    end
  end
end
