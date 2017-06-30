# Encoding: ASCII-8BIT
require 'test_helper'

require 'nesser/packets/question'

module Nesser
  class QuestionTest < ::Test::Unit::TestCase
    def test_question()
      # Create
      question = Question.new(name: 'test.com', type: TYPE_A, cls: CLS_IN)
      assert_equal('test.com', question.name)
      assert_equal(TYPE_A, question.type)
      assert_equal(CLS_IN, question.cls)

      # Stringify
      assert_equal('test.com [A IN]', question.to_s())

      # Pack
      packer = Packer.new()
      question.pack(packer)
      assert_equal("\x04test\x03com\x00\x00\x01\x00\x01", packer.get())

      # Unpack
      unpacker = Unpacker.new(packer.get())
      question = Question.unpack(unpacker)
      assert_equal('test.com', question.name)
      assert_equal(TYPE_A, question.type)
      assert_equal(CLS_IN, question.cls)
    end

    def test_stringify_unknown()
      question = Question.new(name: 'test.com', type: 0x1234, cls: 0x4321)
      assert_equal('test.com [<0x1234?> <0x4321?>]', question.to_s())
    end
  end
end
