# Encoding: ASCII-8BIT
##
# question.rb
# Created June 21, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# This defines a DNS question. One question is sent in outgoing packets,
# and one question is also sent in the response - generally, the same as
# the question that was asked.
##
module DNSer
  class Question
    attr_reader :name, :type, :cls

    def initialize(name:, type:, cls:)
      @name  = name
      @type  = type
      @cls  = cls
    end

    def self.unpack(unpacker)
      name = unpacker.unpack_name()
      type, cls = unpacker.unpack("nn")

      return self.new(name: name, type: type, cls: cls)
    end

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
