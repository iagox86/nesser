# Encoding: ASCII-8BIT
##
# types.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

require 'ipaddr'

require 'dnser/packets/constants'
require 'dnser/dns_exception'
require 'dnser/packets/packer'
require 'dnser/packets/unpacker'

module DNSer
  class A
    attr_accessor :address

    def initialize(address:)
      if !address.is_a?(String)
        raise(FormatException, "String required!")
      end

      begin
        @address = IPAddr.new(address)
      rescue IPAddr::InvalidAddressError => e
        raise(FormatException, "Invalid address: %s" % e)
      end

      if !@address.ipv4?()
        raise(FormatException, "IPv4 address required!")
      end
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length != 4
        raise(FormatException, "Invalid A record!")
      end

      data = unpacker.unpack('a4').join()
      return self.new(address: IPAddr.ntop(data))
    end

    def pack(packer)
      packer.pack('n', 4) # length
      packer.pack('C4', *@address.hton().bytes())
    end

    def to_s()
      return "#{@address} [A]"
    end
  end

  class NS
    attr_accessor :name

    def initialize(name:)
      @name = name
    end

    def self.unpack(unpacker)
      # We don't really need the name for anything, so just discard it
      unpacker.unpack('n')

      return self.new(name: unpacker.unpack_name())
    end

    def pack(packer)
      length = packer.pack_name(@name, dry_run: true)
      packer.pack('n', length)

      packer.pack_name(@name)
    end

    def to_s()
      return "#{@name} [NS]"
    end
  end

  class CNAME
    attr_accessor :name

    def initialize(name:)
      @name = name
    end

    def self.unpack(unpacker)
      # We don't really need the name for anything, so just discard it
      unpacker.unpack('n')

      return self.new(name: unpacker.unpack_name())
    end

    def pack(packer)
      length = packer.pack_name(@name, dry_run: true)
      packer.pack('n', length)
      packer.pack_name(@name)
    end

    def to_s()
      return "#{@name} [CNAME]"
    end
  end

  class SOA
    attr_accessor :primary, :responsible, :serial, :refresh, :retry_interval, :expire, :ttl

    def initialize(primary:, responsible:, serial:, refresh:, retry_interval:, expire:, ttl:)
      @primary = primary
      @responsible = responsible
      @serial = serial
      @refresh = refresh
      @retry_interval = retry_interval
      @expire = expire
      @ttl = ttl
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length < 22
        raise(FormatException, "Invalid SOA record")
      end

      primary = unpacker.unpack_name()
      responsible = unpacker.unpack_name()
      serial, refresh, retry_interval, expire, ttl = unpacker.unpack("NNNNN")

      return self.new(primary: primary, responsible: responsible, serial: serial, refresh: refresh, retry_interval: retry_interval, expire: expire, ttl: ttl)
    end

    def pack(packer)
      length = packer.pack_name(@primary, dry_run: true) + packer.pack_name(@responsible, dry_run: true, compress: false) + 20
      packer.pack('n', length)

      packer.pack_name(@primary)
      # It's a pain to calculate the length when both of these can be
      # compressed, so we're just not going to compress the second name
      packer.pack_name(@responsible, compress: false)
      packer.pack("NNNNN", @serial, @refresh, @retry_interval, @expire, @ttl)
    end

    def to_s()
      return "Primary name server = %s, responsible authority's mailbox: %s, serial number: 0x%08x, refresh interval: 0x%08x, retry interval: 0x%08x, expire limit: 0x%08x, min_ttl: 0x%08x, [SOA]" % [
        @primary,
        @responsible,
        @serial,
        @refresh,
        @retry_interval,
        @expire,
        @ttl,
      ]
    end
  end

  class MX
    attr_accessor :preference, :name

    def initialize(name:, preference:)
      @name = name
      @preference = preference
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length < 3
        raise(FormatException, "Invalid MX record")
      end

      preference = unpacker.unpack_one('n')
      name = unpacker.unpack_name()

      return self.new(name: name, preference: preference)
    end

    def pack(packer)
      length = packer.pack_name(@name, dry_run: true) + 2
      packer.pack('n', length)

      packer.pack('n', @preference)
      packer.pack_name(@name)
    end

    def to_s()
      return "#{@preference} #{@name} [MX]"
    end
  end

  class TXT
    attr_accessor :data

    def initialize(data:)
      @data = data
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length < 1
        raise(FormatException, "Invalid TXT record")
      end

      len = unpacker.unpack_one("C")

      if len != length - 1
        raise(FormatException, "Invalid TXT record")
      end

      data = unpacker.unpack_one("a#{len}")

      return self.new(data: data)
    end

    def pack(packer)
      packer.pack('n', @data.length + 1)

      packer.pack('Ca*', @data.length, @data)
    end

    def to_s()
      return "#{@data} [TXT]"
    end
  end

  class AAAA
    attr_accessor :address

    def initialize(address:)
      if !address.is_a?(String)
        raise(FormatException, "String required!")
      end

      begin
        @address = IPAddr.new(address)
      rescue IPAddr::InvalidAddressError => e
        raise(FormatException, "Invalid address: %s" % e)
      end

      if !@address.ipv6?()
        raise(FormatException, "IPv6 address required!")
      end
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length != 16
        raise(FormatException, "Invalid AAAA record")
      end

      data = unpacker.unpack('a16').join()
      return self.new(address: IPAddr.ntop(data))
    end

    def pack(packer)
      packer.pack('n', 16)

      packer.pack('C16', *@address.hton().bytes())
    end


    def to_s()
      return "#{@address} [AAAA]"
    end
  end

  class RRUnknown
    attr_reader :type, :data
    def initialize(type:, data:)
      @type = type
      @data = data
    end

    def self.unpack(unpacker, type)
      length = unpacker.unpack_one('n')
      data = unpacker.unpack_one("a#{length}")
      return self.new(type: type, data: data)
    end

    def pack(packer)
      packer.pack('n', @data.length)

      packer.pack('a*', @data)
    end

    def to_s()
      return "(Unknown record type 0x%04x: %s)" % [@type, @data]
    end
  end
end
