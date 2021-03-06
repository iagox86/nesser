# Encoding: ASCII-8BIT
##
# types.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# These are implementations of resource records - ie, the records found in a DNS
# answer that contain, for example, an ip address, a mail exchange, etc.
#
# Every one of these classes follows the same paradigm (I guess in Java you'd
# say they implement the same interface). They can be initialized with
# type-dependent parameters; they implement `self.unpack()`, which takes a
# `Nesser::Unpacker` and returns an instance of itself; they implement `pack()`,
# which serialized itself into a `Nesser::Packer` instance; and they have a
# `to_s()` function, which stringifies the record in a fairly user-friendly way.
##

require 'ipaddr'

require 'nesser/packets/constants'
require 'nesser/dns_exception'
require 'nesser/packets/packer'
require 'nesser/packets/unpacker'

module Nesser
  ##
  # An A record is a typical IPv4 address - eg, '1.2.3.4'.
  ##
  class A
    attr_accessor :address

    def initialize(address:)
      if !address.is_a?(String)
        raise(DnsException, "String required!")
      end

      begin
        @address = IPAddr.new(address)
      rescue IPAddr::InvalidAddressError => e
        raise(DnsException, "Invalid address: %s" % e)
      end

      if !@address.ipv4?()
        raise(DnsException, "IPv4 address required!")
      end
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length != 4
        raise(DnsException, "Invalid A record!")
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

  ##
  # Nameserver record: eg, 'ns1.google.com'.
  ##
  class NS
    attr_accessor :name

    def initialize(name:)
      @name = name
    end

    def self.unpack(unpacker)
      # We don't really need the length for anything, so just discard it
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

  ##
  # Alias record: eg, 'www.google.com'->'google.com'.
  ##
  class CNAME
    attr_accessor :name

    def initialize(name:)
      @name = name
    end

    def self.unpack(unpacker)
      # We don't really need the length for anything, so just discard it
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

  ##
  # Statement of authority record.
  ##
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
        raise(DnsException, "Invalid SOA record")
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

  ##
  # PTR record - ie, reverse DNS
  ##
  class PTR
    attr_accessor :name

    def initialize(name:)
      @name = name
    end

    def self.unpack(unpacker)
      # We don't really need the length for anything, so just discard it
      unpacker.unpack('n')

      return self.new(name: unpacker.unpack_name())
    end

    def pack(packer)
      length = packer.pack_name(@name, dry_run: true)
      packer.pack('n', length)
      packer.pack_name(@name)
    end

    def to_s()
      return "#{@name} [PTR]"
    end
  end

  ##
  # Mail exchange record - eg, 'mail.google.com' 10.
  ##
  class MX
    attr_accessor :preference, :name

    def initialize(name:, preference:)
      @name = name
      @preference = preference
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length < 3
        raise(DnsException, "Invalid MX record")
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

  ##
  # A TXT record, with is simply binary data (except on some libraries where it
  # can't contain a NUL byte).
  ##
  class TXT
    attr_accessor :data

    def initialize(data:)
      @data = data
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length < 1
        raise(DnsException, "Invalid TXT record")
      end

      len = unpacker.unpack_one("C")

      if len != length - 1
        raise(DnsException, "Invalid TXT record")
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

  ##
  # IPv6 record, eg, "::1".
  ##
  class AAAA
    attr_accessor :address

    def initialize(address:)
      if !address.is_a?(String)
        raise(DnsException, "String required!")
      end

      begin
        @address = IPAddr.new(address)
      rescue IPAddr::InvalidAddressError => e
        raise(DnsException, "Invalid address: %s" % e)
      end

      if !@address.ipv6?()
        raise(DnsException, "IPv6 address required!")
      end
    end

    def self.unpack(unpacker)
      length = unpacker.unpack_one('n')
      if length != 16
        raise(DnsException, "Invalid AAAA record")
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

  ##
  # An unknown record type.
  ##
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
