# Encoding: ASCII-8BIT
##
# answer.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# A DNS answer. A DNS response packet contains zero or more Answer records
# (defined by the 'ancount' value in the header). An answer contains the
# name of the domain from the question, followed by a resource record.
##

module DNSer
  class Answer
    attr_reader :name, :type, :cls, :ttl, :rr

    def initialize(name:, type:, cls:, ttl:, rr:)
      @name = name
      @type = type
      @cls  = cls
      @ttl  = ttl
      @rr   = rr
    end

    def self.unpack(unpacker)
      name = unpacker.unpack_name()
      type, cls, ttl = unpacker.unpack("nnN")

      case type
      when TYPE_A
        rr = A.unpack(unpacker)
      when TYPE_NS
        rr = NS.unpack(unpacker)
      when TYPE_CNAME
        rr = CNAME.unpack(unpacker)
      when TYPE_SOA
        rr = SOA.unpack(unpacker)
      when TYPE_MX
        rr = MX.unpack(unpacker)
      when TYPE_TXT
        rr = TXT.unpack(unpacker)
      when TYPE_AAAA
        rr = AAAA.unpack(unpacker)
      else
        rr = RRUnknown.unpack(unpacker, type)
      end

      return self.new(
        name: name,
        type: type,
        cls: cls,
        ttl: ttl,
        rr: rr,
      )
    end

    def pack(packer)
      # The name is echoed back
      packer.pack_name(@name)

      # The type/class/ttl are added
      packer.pack('nnN', @type, @cls, @ttl)

      # Finally, the length and rr (the length is included)
      @rr.pack(packer)
    end

    def to_s()
      return '%s %d [%s %s] %s' % [
        @name,
        @ttl,
        TYPES[@type] || '<0x%04x?>' % @type,
        CLSES[@cls]  || '<0x%04x?>' % @cls,
        @rr.to_s(),
      ]
    end
  end
end
