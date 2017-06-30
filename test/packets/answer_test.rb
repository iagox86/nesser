# Encoding: ASCII-8BIT
require 'test_helper'
require 'nesser/packets/rr_types'
require 'nesser/packets/answer'

module Nesser
  class AnswerTest < ::Test::Unit::TestCase
    def test_answer()
      # Create
      answer = Answer.new(
        name: 'test.com',
        type: TYPE_CNAME,
        cls: CLS_IN,
        ttl: 0x12345678,
        rr: CNAME.new(name: 'server.test.com'),
      )
      assert_equal('test.com', answer.name)
      assert_equal(TYPE_CNAME, answer.type)
      assert_equal(CLS_IN, answer.cls)
      assert_equal(0x12345678, answer.ttl)
      assert_equal('server.test.com', answer.rr.name)

      # Stringify
      expected = 'test.com 305419896 [CNAME IN] server.test.com [CNAME]'
      assert_equal(expected, answer.to_s())

      # Pack
      packer = Packer.new()
      answer.pack(packer)

      expected = "\x04test\x03com\x00" + # name
        "\x00\x05" + # type = CNAME
        "\x00\x01" + # cls = IN
        "\x12\x34\x56\x78" + # ttl
        "\x00\x09" + # rr length
        "\x06server\xc0\x00" # name
      assert_equal(expected, packer.get())

      # Unpack
      unpacker = Unpacker.new(packer.get())
      answer = Answer.unpack(unpacker)
      assert_equal('test.com', answer.name)
      assert_equal(TYPE_CNAME, answer.type)
      assert_equal(CLS_IN, answer.cls)
      assert_equal(0x12345678, answer.ttl)
      assert_equal('server.test.com', answer.rr.name)
    end

    def test_unknown_rr()
      data = "\x04test\x03com\x00" + # name
        "\x13\x37" + # type = unknown
        "\x00\x01" + # cls = IN
        "\x12\x34\x56\x78" + # ttl
        "\x00\x10" + # rr length
        "AAAAAAAAAAAAAAAA" # name
      unpacker = Unpacker.new(data)
      answer = Answer.unpack(unpacker)

      assert_equal('test.com', answer.name)
      assert_equal(0x1337, answer.type)
      assert_equal(CLS_IN, answer.cls)
      assert_equal(0x12345678, answer.ttl)
      assert_equal('AAAAAAAAAAAAAAAA', answer.rr.data)
    end
  end
end
