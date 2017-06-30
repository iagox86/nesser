# Encoding: ASCII-8BIT
require 'test_helper'

require 'nesser/packets/rr_types'

module Nesser
  class A_Test < ::Test::Unit::TestCase
    def test_a()
      # Create
      record = A.new(address: '1.2.3.4')
      assert_equal(IPAddr.new('1.2.3.4'), record.address)

      # Stringify
      assert_equal('1.2.3.4 [A]', record.to_s)

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x04\x01\x02\x03\x04", packer.get())
    end

    def test_unpack_a()
      unpacker = Unpacker.new("\x00\x04ABCD")
      record = A.unpack(unpacker)
      assert_equal(IPAddr.new('65.66.67.68'), record.address)
    end

    def test_unpack_invalid_A()
      unpacker = Unpacker.new("\x00\x05ABCD")
      assert_raises(FormatException) do
        A.unpack(unpacker)
      end
    end

    def test_invalid_a()
      assert_raises(FormatException) do
        A.new(address: 123)
      end
      assert_raises(FormatException) do
        A.new(address: '::1')
      end
      assert_raises(FormatException) do
        A.new(address: '500.hi')
      end
    end
  end

  class NS_Test < ::Test::Unit::TestCase
    def test_ns()
      # Create
      record = NS.new(name: 'test.com')
      assert_equal('test.com', record.name)

      # Stringify
      assert_equal('test.com [NS]', record.to_s)

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x0a\x04test\x03com\x00", packer.get())
    end

    def test_unpack_ns()
      unpacker = Unpacker.new("\x00\x0a\x04test\x03com\x00")
      record = NS.unpack(unpacker)
      assert_equal('test.com', record.name)
    end
  end

  class CNAME_Test < ::Test::Unit::TestCase
    def test_cname()
      # Create
      record = CNAME.new(name: 'test.com')
      assert_equal('test.com', record.name)

      # Stringify
      assert_equal('test.com [CNAME]', record.to_s)

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x0a\x04test\x03com\x00", packer.get())
    end

    def test_unpack_cname()
      unpacker = Unpacker.new("\x00\x0a\x04test\x03com\x00")
      record = CNAME.unpack(unpacker)
      assert_equal('test.com', record.name)
    end
  end

  class SOA_Test < ::Test::Unit::TestCase
    def test_soa()
      # Create
      record = SOA.new(
        primary: 'test.com',
        responsible: 'other.test.com',
        serial: 0x41424344,
        refresh: 0x45464748,
        retry_interval: 0x494a4b4c,
        expire: 0x4d4e4f50,
        ttl: 0x51525354,
      )
      assert_equal('test.com', record.primary)
      assert_equal('other.test.com', record.responsible)
      assert_equal(0x41424344, record.serial)
      assert_equal(0x45464748, record.refresh)
      assert_equal(0x494a4b4c, record.retry_interval)
      assert_equal(0x4d4e4f50, record.expire)
      assert_equal(0x51525354, record.ttl)

      # Stringify
      expected = "Primary name server = test.com, " +
        "responsible authority's mailbox: other.test.com, " +
        "serial number: 0x41424344, " +
        "refresh interval: 0x45464748, " +
        "retry interval: 0x494a4b4c, " +
        "expire limit: 0x4d4e4f50, " +
        "min_ttl: 0x51525354, [SOA]"
      assert_equal(expected, record.to_s)

      # Pack
      packer = Packer.new()
      record.pack(packer)
      expected = "\x00\x2e" +
        "\x04test\x03com\x00" +
        "\x05other\x04test\x03com\x00" +
        "\x41\x42\x43\x44" +
        "\x45\x46\x47\x48" +
        "\x49\x4a\x4b\x4c" +
        "\x4d\x4e\x4f\x50" +
        "\x51\x52\x53\x54"
      assert_equal(expected, packer.get())
    end

    def test_unpack_soa()
      unpacker = Unpacker.new("\x00\x24" +
        "\x04test\x03com\x00" +
        "\x05other\xc0\x02" +
        "\x41\x42\x43\x44" +
        "\x45\x46\x47\x48" +
        "\x49\x4a\x4b\x4c" +
        "\x4d\x4e\x4f\x50" +
        "\x51\x52\x53\x54"
      )
      record = SOA.unpack(unpacker)
      assert_equal('test.com', record.primary)
      assert_equal('other.test.com', record.responsible)
      assert_equal(0x41424344, record.serial)
      assert_equal(0x45464748, record.refresh)
      assert_equal(0x494a4b4c, record.retry_interval)
      assert_equal(0x4d4e4f50, record.expire)
      assert_equal(0x51525354, record.ttl)
    end
  end

  class MX_Test < ::Test::Unit::TestCase
    def test_mx()
      # Create
      record = MX.new(name: 'test.com', preference: 10)
      assert_equal('test.com', record.name)
      assert_equal(10, record.preference)

      # Stringify
      assert_equal('10 test.com [MX]', record.to_s())

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x0c\x00\x0a\x04test\x03com\x00", packer.get())
    end

    def test_unpack_mx()
      unpacker = Unpacker.new("\x00\x0c\x00\x0a\x04test\x03com\x00")
      record = MX.unpack(unpacker)
      assert_equal('test.com', record.name)
      assert_equal(10, record.preference)
    end
  end

  class TXT_Test < ::Test::Unit::TestCase
    def test_txt()
      # Create
      record = TXT.new(data: 'Hello world!')
      assert_equal('Hello world!', record.data)

      # Stringify
      assert_equal('Hello world! [TXT]', record.to_s())

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x0d\x0cHello world!", packer.get())
    end

    def test_unpack_txt()
      unpacker = Unpacker.new("\x00\x0d\x0cHello world!")
      record = TXT.unpack(unpacker)
      assert_equal('Hello world!', record.data)
    end
  end

  class AAAA_Test < ::Test::Unit::TestCase
    def test_aaaa()
      # Create
      record = AAAA.new(address: '2001:db8:85a3::8a2e:370:7334')
      assert_equal(IPAddr.new('2001:db8:85a3::8a2e:370:7334'), record.address)

      # Stringify
      assert_equal('2001:db8:85a3::8a2e:370:7334 [AAAA]', record.to_s)

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x10\x20\x01\x0d\xb8\x85\xa3\x00\x00\x00\x00\x8a\x2e\x03\x70\x73\x34", packer.get())
    end

    def test_unpack_aaaa()
      unpacker = Unpacker.new("\x00\x10\x20\x01\x0d\xb8\x85\xa3\x00\x00\x00\x00\x8a\x2e\x03\x70\x73\x34")
      record = AAAA.unpack(unpacker)
      assert_equal(IPAddr.new('2001:db8:85a3::8a2e:370:7334'), record.address)
    end

    def test_invalid_aaaa()
      assert_raises(FormatException) do
        AAAA.new(address: 123)
      end
      assert_raises(FormatException) do
        AAAA.new(address: '1.2.3.4')
      end
      assert_raises(FormatException) do
        AAAA.new(address: '500.hi')
      end
    end
  end

  class RRUnknown_Test < ::Test::Unit::TestCase
    def test_rrunknown()
      # Create
      record = RRUnknown.new(type: 0x1337, data: 'hihihi')
      assert_equal(0x1337, record.type)
      assert_equal('hihihi', record.data)

      # Stringify
      assert_equal('(Unknown record type 0x1337: hihihi)', record.to_s())

      # Pack
      packer = Packer.new()
      record.pack(packer)
      assert_equal("\x00\x06hihihi", packer.get())
    end

    def test_unpack_rrunknown()
      unpacker = Unpacker.new("\x00\x06hihihi")
      record = RRUnknown.unpack(unpacker, 0x1337)
      assert_equal(0x1337, record.type)
      assert_equal('hihihi', record.data)
    end
  end
end
