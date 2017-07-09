# Encoding: ASCII-8BIT
##
# packet.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

require 'nesser/dns_exception'
require 'nesser/packets/answer'
require 'nesser/packets/constants'
require 'nesser/packets/packer'
require 'nesser/packets/question'
require 'nesser/packets/rr_types'
require 'nesser/packets/unpacker'

module Nesser
  class Packet
    attr_accessor :trn_id, :qr, :opcode, :flags, :rcode, :questions, :answers

    def initialize(trn_id:, qr:, opcode:, flags:, rcode:, questions:[], answers:[])
      @trn_id    = trn_id
      @qr        = qr
      @opcode    = opcode
      @flags     = flags
      @rcode     = rcode

      questions.each { |q| raise(DnsException, "Questions must be of type Answer!") if !q.is_a?(Question) }
      @questions = questions

      answers.each { |a| raise(DnsException, "Answers must be of type Answer!") if !a.is_a?(Answer) }
      @answers   = answers
    end

    def add_question(question)
      if !question.is_a?(Question)
        raise(DnsException, "Questions must be of type Question!")
      end

      @questions << question
    end

    def add_answer(answer)
      if !answer.is_a?(Answer)
        raise(DnsException, "Questions must be of type Question!")
      end

      @answers << answer
    end

    def self.parse(data)
      unpacker = Unpacker.new(data)
      trn_id, full_flags, qdcount, ancount, _, _ = unpacker.unpack("nnnnnn")

      qr     = (full_flags >> 15) & 0x0001
      opcode = (full_flags >> 11) & 0x000F
      flags  = (full_flags >> 7)  & 0x000F
      rcode  = (full_flags >> 0)  & 0x000F

      packet = self.new(
        trn_id: trn_id,
        qr: qr,
        opcode: opcode,
        flags: flags,
        rcode: rcode,
        questions: [],
        answers: [],
      )

      0.upto(qdcount - 1) do
        question = Question.unpack(unpacker)
        packet.add_question(question)
      end

      0.upto(ancount - 1) do
        answer = Answer.unpack(unpacker)
        packet.add_answer(answer)
      end

      return packet
    end

    def answer(answers:[], question:nil)
      question = question || @questions[0]

      return Packet.new(
        trn_id: @trn_id,
        qr: QR_RESPONSE,
        opcode: OPCODE_QUERY,
        flags: FLAG_RD | FLAG_RA,
        rcode: RCODE_SUCCESS,
        questions: [question],
        answers: answers,
      )
    end

    def error(rcode:, question:nil)
      question = question || @questions[0]

      return Packet.new(
        trn_id: @trn_id,
        qr: QR_RESPONSE,
        opcode: OPCODE_QUERY,
        flags: FLAG_RD | FLAG_RA,
        rcode: rcode,
        questions: [question],
        answers: [],
      )
    end

    def to_bytes()
      packer = Packer.new()

      full_flags = ((@qr     << 15) & 0x8000) |
                   ((@opcode << 11) & 0x7800) |
                   ((@flags  <<  7) & 0x0780) |
                   ((@rcode  <<  0) & 0x000F)

      packer.pack('nnnnnn',
        @trn_id,             # trn_id
        full_flags,          # qr, opcode, flags, rcode
        @questions.length(), # qdcount
        @answers.length(),   # ancount
        0,                   # nscount (we don't handle)
        0,                   # arcount (we don't handle)
      )

      questions.each do |q|
        q.pack(packer)
      end

      answers.each do |a|
        a.pack(packer)
      end

      return packer.get()
    end

    def to_s(brief:false)
      if(brief)
        question = @questions[0] || '<unknown>'

        # Print error packets more clearly
        if(@rcode != RCODE_SUCCESS)
          return "Request for #{question}: error: #{RCODES[@rcode]}"
        end

        if(@qr == QR_QUERY)
          return "Request for #{question}"
        else
          if(@answers.length == 0)
            return "Response for %s: n/a" % question.to_s
          else
            return "Response for %s: %s (and %d others)" % [
              question.to_s(),
              @answers[0].to_s(),
              @answers.length - 1,
            ]
          end
        end
      end

      results = []
      results << "DNS %s: id=0x%04x, opcode = %s, flags = %s, rcode = %s, qdcount = 0x%04x, ancount = 0x%04x" % [
        QRS[@qr] || "unknown",
        @trn_id,
        OPCODES[@opcode] || "unknown opcode",
        ::Nesser::FLAGS(@flags),
        RCODES[@rcode] || "unknown",
        @questions.length,
        @answers.length,
      ]

      @questions.each do |q|
        results << "    Question: %s" % q.to_s()
      end

      @answers.each do |a|
        results << "    Answer: %s" % a.to_s()
      end

      return results.join("\n")
    end
  end
end
