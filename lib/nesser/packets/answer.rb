# Encoding: ASCII-8BIT
##
# answer.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# A DNS answer. A DNS packet contains zero or more Answer records (defined in
# the 'ancount' value in the header). An answer contains the name of the domain
# followed by a resource record.
##

module Nesser
  class Answer
    attr_reader :name, :type, :cls, :ttl, :rr

    ##
    # Create an answer.
    #
    # * `name`: Should match the name from the question.
    # * `type`: The type of resource record (eg, TYPE_A, TYPE_NS, etc). You can
    #   find a list of types in constants.rb.
    # * `cls`: The DNS class - this will almost certainly be `Nesser::CLS_IN`,
    #   since 'IN' means 'Internet'. I'm not familiar with any others.
    # * `ttl`: The time-to-live for the response, in seconds
    # * `rr`: A resource record - you can find these classes in rr_types.rb.
    ##
    def initialize(name:, type:, cls:, ttl:, rr:)
      @name = name
      @type = type
      @cls  = cls
      @ttl  = ttl
      @rr   = rr
    end

    ##
    # Parse an answer from a DNS packet. You won't likely need to use this, but
    # if you do, it's necessary to use a Nesser::Unpacker that's loaded with the
    # full DNS message (due to in-packet pointers).
    ##
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
      when TYPE_PTR
        rr = PTR.unpack(unpacker)
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

    ##
    # Pack this into a Nesser::Packer in preparation for being sent over the
    # wire.
    ##
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
