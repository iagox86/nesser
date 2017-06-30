# Encoding: ASCII-8BIT
require 'test_helper'
require 'nesser/packets/answer'
require 'nesser/packets/packet'
require 'nesser/packets/question'
require 'nesser/packets/rr_types'

require 'nesser/transaction'

module Nesser
  class AnswerTest2 < ::Test::Unit::TestCase
    def test_answer()
      s = FakeSocket.new()

      packet = Packet.new(trn_id: 0x1337, qr: QR_QUERY, opcode: OPCODE_QUERY, flags: FLAG_RD, rcode: RCODE_SUCCESS)
      packet.add_question(Question.new(name: 'test.com', type: TYPE_AAAA, cls: CLS_IN))

      transaction = Transaction.new(
        s: s,
        request_packet: packet,
        host: 'example.org',
        port: 6112,
      )

      transaction.answer!([
        Answer.new(name: 'test.com', type: TYPE_AAAA, cls: CLS_IN, ttl: 0x12345678, rr: AAAA.new(address: '::1')),
        Answer.new(name: 'test.com', type: TYPE_AAAA, cls: CLS_IN, ttl: 0x12345678, rr: AAAA.new(address: '::2')),
      ])

      expected = "\x13\x37" + # trn_id
        "\x81\x80" + # Flags
        "\x00\x01" + # qdcount
        "\x00\x02" + # ancount
        "\x00\x00" +
        "\x00\x00" +

        # Question
        "\x04test\x03com\x00" + # Name
        "\x00\x1c" + # Type = AAAA
        "\x00\x01" + # Cls = IN

        # Answer 1
        "\xc0\x0c" + # Name
        "\x00\x1c" + # Type
        "\x00\x01" + # Cls
        "\x12\x34\x56\x78" + # TTL
        "\x00\x10" + # RR LEngth
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01" + # RR

        # Answer 2
        "\xc0\x0c" + # Name
        "\x00\x1c" + # Type
        "\x00\x01" + # Cls
        "\x12\x34\x56\x78" + # TTL
        "\x00\x10" + # RR LEngth
        "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02" # RR

      assert_equal(1, s.out.length)
      assert_equal(expected, s.out[0][:data])
    end

    def test_error()
      s = FakeSocket.new()

      packet = Packet.new(trn_id: 0x1337, qr: QR_QUERY, opcode: OPCODE_QUERY, flags: FLAG_RD, rcode: RCODE_SUCCESS)
      packet.add_question(Question.new(name: 'test.com', type: TYPE_AAAA, cls: CLS_IN))

      transaction = Transaction.new(
        s: s,
        request_packet: packet,
        host: 'example.org',
        port: 6112,
      )

      transaction.error!(RCODE_NAME_ERROR)

      expected = "\x13\x37" + # trn_id
        "\x81\x83" + # Flags
        "\x00\x01" + # qdcount
        "\x00\x00" + # ancount
        "\x00\x00" +
        "\x00\x00" +

        # Question
        "\x04test\x03com\x00" + # Name
        "\x00\x1c" + # Type = AAAA
        "\x00\x01" # Cls = IN

      assert_equal(1, s.out.length)
      assert_equal(expected, s.out[0][:data])
    end
  end
end
