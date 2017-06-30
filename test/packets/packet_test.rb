# Encoding: ASCII-8BIT
require 'test_helper'

require 'nesser/packets/packet'

module Nesser
  class PacketTest < ::Test::Unit::TestCase
    def test_create_parse_question()
      packet = Packet.new(
        trn_id: 0x1337,
        qr: QR_QUERY,
        opcode: OPCODE_QUERY,
        flags: FLAG_RD | FLAG_AA | FLAG_RA | FLAG_TC,
        rcode: RCODE_SUCCESS,
      )
      assert_equal(0x1337, packet.trn_id)
      assert_equal(QR_QUERY, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD | FLAG_AA | FLAG_RA | FLAG_TC, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)

      packet.add_question(
        Question.new(
          name: 'google.com',
          type: TYPE_A,
          cls: CLS_IN,
        )
      )
      assert_equal('google.com', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)

      expected = "\x13\x37" + # trn_id
        "\x07\x80" + # Flags
        "\x00\x01" + # qdcount
        "\x00\x00" + # ancount
        "\x00\x00" + # nscount
        "\x00\x00" + # arcount
        "\x06google\x03com\x00" + # name
        "\x00\x01" + # type
        "\x00\x01" # cls
      assert_equal(expected, packet.to_bytes)

      packet = Packet.parse(packet.to_bytes)
      assert_equal(0x1337, packet.trn_id)
      assert_equal(QR_QUERY, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD | FLAG_AA | FLAG_RA | FLAG_TC, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)
      assert_equal('google.com', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)

      # Test the to_s method while we're at it
      expected_long = "DNS QUERY: id=0x1337, opcode = OPCODE_QUERY, flags = AA|TC|RD|RA, rcode = :NoError (RCODE_SUCCESS), qdcount = 0x0001, ancount = 0x0000\n" +
        "    Question: google.com [A IN]"
      assert_equal(expected_long, packet.to_s())

      expected_brief = "Request for google.com [A IN]"
      assert_equal(expected_brief, packet.to_s(brief: true))
    end

    def test_create_parse_answer()
      packet = Packet.new(
        trn_id: 0x1337,
        qr: QR_RESPONSE,
        opcode: OPCODE_QUERY,
        flags: FLAG_RD,
        rcode: RCODE_SUCCESS,
      )
      assert_equal(0x1337, packet.trn_id)
      assert_equal(QR_RESPONSE, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)

      packet.add_question(
        Question.new(
          name: 'google.com',
          type: TYPE_A,
          cls: CLS_IN,
        )
      )
      assert_equal('google.com', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)

      packet.add_answer(
        Answer.new(
          name: 'google.com',
          type: TYPE_A,
          cls: CLS_IN,
          ttl: 0x12345678,
          rr: A.new(
            address: '1.2.3.4'
          ),
        ),
      )

      packet.add_answer(
        Answer.new(
          name: 'google.com',
          type: TYPE_MX,
          cls: CLS_IN,
          ttl: 0x12345678,
          rr: MX.new(
            name: 'mail.google.com',
            preference: 10,
          ),
        ),
      )
      assert_equal('google.com', packet.answers[0].name)
      assert_equal(TYPE_A, packet.answers[0].type)
      assert_equal(CLS_IN, packet.answers[0].cls)
      assert_equal(0x12345678, packet.answers[0].ttl)
      assert_equal(IPAddr.new('1.2.3.4'), packet.answers[0].rr.address)

      assert_equal('google.com', packet.answers[1].name)
      assert_equal(TYPE_MX, packet.answers[1].type)
      assert_equal(CLS_IN, packet.answers[1].cls)
      assert_equal(0x12345678, packet.answers[1].ttl)
      assert_equal('mail.google.com', packet.answers[1].rr.name)
      assert_equal(10, packet.answers[1].rr.preference)

      expected = "\x13\x37" + # trn_id
        "\x81\x00" + # Flags
        "\x00\x01" + # qdcount
        "\x00\x02" + # ancount
        "\x00\x00" + # nscount
        "\x00\x00" + # arcount

        # Question
        "\x06google\x03com\x00" + # name
        "\x00\x01" + # type
        "\x00\x01" + # cls

        # First answer
        "\xc0\x0c" + # name
        "\x00\x01" + # type
        "\x00\x01" + # cls
        "\x12\x34\x56\x78" + # TTL
        "\x00\x04" + # rr length
        "\x01\x02\x03\x04" + # A rr

        # Second answer
        "\xc0\x0c" + # name
        "\x00\x0f" + # type
        "\x00\x01" + # cls
        "\x12\x34\x56\x78" + # TTL
        "\x00\x09" + # rr length
        "\x00\x0a\x04mail\xc0\x0c" # MX rr (name + preference)

      assert_equal(expected, packet.to_bytes)

      packet = Packet.parse(packet.to_bytes)

      assert_equal(0x1337, packet.trn_id)
      assert_equal(QR_RESPONSE, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)
      assert_equal('google.com', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)
      assert_equal('google.com', packet.answers[0].name)
      assert_equal(TYPE_A, packet.answers[0].type)
      assert_equal(CLS_IN, packet.answers[0].cls)
      assert_equal(0x12345678, packet.answers[0].ttl)
      assert_equal(IPAddr.new('1.2.3.4'), packet.answers[0].rr.address)
      assert_equal('google.com', packet.answers[1].name)
      assert_equal(TYPE_MX, packet.answers[1].type)
      assert_equal(CLS_IN, packet.answers[1].cls)
      assert_equal(0x12345678, packet.answers[1].ttl)
      assert_equal('mail.google.com', packet.answers[1].rr.name)
      assert_equal(10, packet.answers[1].rr.preference)

      expected_long = "DNS RESPONSE: id=0x1337, opcode = OPCODE_QUERY, flags = RD, rcode = :NoError (RCODE_SUCCESS), qdcount = 0x0001, ancount = 0x0002\n" +
        "    Question: google.com [A IN]\n" +
        "    Answer: google.com 305419896 [A IN] 1.2.3.4 [A]\n" +
        "    Answer: google.com 305419896 [MX IN] 10 mail.google.com [MX]"
      assert_equal(expected_long, packet.to_s())

      expected_brief = "Response for google.com [A IN]: google.com 305419896 [A IN] 1.2.3.4 [A] (and 1 others)"
      assert_equal(expected_brief, packet.to_s(brief: true))
    end

    def test_parse_real_request()
      # Generated with `dig @8.8.8.8 -t A skullsecurity.org`
      request = "\x8d\xbe\x01\x20\x00\x01\x00\x00\x00\x00\x00\x01\x0d\x73\x6b\x75" +
        "\x6c\x6c\x73\x65\x63\x75\x72\x69\x74\x79\x03\x6f\x72\x67\x00\x00" +
        "\x01\x00\x01\x00\x00\x29\x10\x00\x00\x00\x00\x00\x00\x00"
      packet = Packet.parse(request)
      assert_equal(0x8dbe, packet.trn_id)
      assert_equal(QR_QUERY, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)
      assert_equal('skullsecurity.org', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)
    end

    def test_parse_real_response()
      # Generated with `dig @8.8.8.8 -t ANY skullsecurity.org`
      response = "\xe9\x50\x81\x80\x00\x01\x00\x0b\x00\x00\x00\x01\x0d\x73\x6b\x75" +
        "\x6c\x6c\x73\x65\x63\x75\x72\x69\x74\x79\x03\x6f\x72\x67\x00\x00" +
        "\xff\x00\x01\xc0\x0c\x00\x01\x00\x01\x00\x00\x0e\x0f\x00\x04\xc0" +
        "\x9b\x51\x56\xc0\x0c\x00\x02\x00\x01\x00\x00\x0e\x0f\x00\x18\x04" +
        "\x6e\x73\x31\x39\x0d\x64\x6f\x6d\x61\x69\x6e\x63\x6f\x6e\x74\x72" +
        "\x6f\x6c\x03\x63\x6f\x6d\x00\xc0\x0c\x00\x02\x00\x01\x00\x00\x0e" +
        "\x0f\x00\x07\x04\x6e\x73\x32\x30\xc0\x44\xc0\x0c\x00\x06\x00\x01" +
        "\x00\x00\x0e\x0f\x00\x25\xc0\x3f\x03\x64\x6e\x73\x05\x6a\x6f\x6d" +
        "\x61\x78\x03\x6e\x65\x74\x00\x78\x39\x70\x3e\x00\x00\x70\x80\x00" +
        "\x00\x1c\x20\x00\x09\x3a\x80\x00\x00\x0e\x10\xc0\x0c\x00\x0f\x00" +
        "\x01\x00\x00\x0e\x0f\x00\x18\x00\x05\x04\x41\x4c\x54\x31\x05\x41" +
        "\x53\x50\x4d\x58\x01\x4c\x06\x47\x4f\x4f\x47\x4c\x45\xc0\x52\xc0" +
        "\x0c\x00\x0f\x00\x01\x00\x00\x0e\x0f\x00\x09\x00\x05\x04\x41\x4c" +
        "\x54\x32\xc0\xae\xc0\x0c\x00\x0f\x00\x01\x00\x00\x0e\x0f\x00\x16" +
        "\x00\x0a\x06\x41\x53\x50\x4d\x58\x32\x0a\x47\x4f\x4f\x47\x4c\x45" +
        "\x4d\x41\x49\x4c\xc0\x52\xc0\x0c\x00\x0f\x00\x01\x00\x00\x0e\x0f" +
        "\x00\x0b\x00\x0a\x06\x41\x53\x50\x4d\x58\x33\xc0\xe9\xc0\x0c\x00" +
        "\x0f\x00\x01\x00\x00\x0e\x0f\x00\x04\x00\x01\xc0\xae\xc0\x0c\x00" +
        "\x10\x00\x01\x00\x00\x0e\x0f\x00\x45\x44\x67\x6f\x6f\x67\x6c\x65" +
        "\x2d\x73\x69\x74\x65\x2d\x76\x65\x72\x69\x66\x69\x63\x61\x74\x69" +
        "\x6f\x6e\x3d\x75\x49\x63\x42\x46\x76\x4e\x58\x53\x53\x61\x41\x45" +
        "\x49\x6b\x67\x36\x6b\x5a\x33\x5f\x5a\x4c\x41\x56\x70\x43\x6e\x41" +
        "\x6d\x49\x33\x50\x49\x75\x49\x7a\x77\x72\x62\x70\x76\x38\xc0\x0c" +
        "\x00\x10\x00\x01\x00\x00\x0e\x0f\x00\x0b\x0a\x6f\x68\x20\x68\x61" +
        "\x69\x20\x4e\x53\x41\x00\x00\x29\x02\x00\x00\x00\x00\x00\x00\x00"
      packet = Packet.parse(response)

      assert_equal(0xe950, packet.trn_id)
      assert_equal(QR_RESPONSE, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD | FLAG_RA, packet.flags)
      assert_equal(RCODE_SUCCESS, packet.rcode)

      # Echoing back the question
      assert_equal('skullsecurity.org', packet.questions[0].name)
      assert_equal(TYPE_ANY, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)

      # Answer: skullsecurity.org.      3599    IN      A       192.155.81.86
      assert_equal('skullsecurity.org', packet.answers[0].name)
      assert_equal(TYPE_A, packet.answers[0].type)
      assert_equal(CLS_IN, packet.answers[0].cls)
      assert_equal(3599, packet.answers[0].ttl)
      assert_equal(IPAddr.new('192.155.81.86'), packet.answers[0].rr.address)

      # Answer: skullsecurity.org.      3599    IN      NS      ns19.domaincontrol.com.
      assert_equal('skullsecurity.org', packet.answers[1].name)
      assert_equal(TYPE_NS, packet.answers[1].type)
      assert_equal(CLS_IN, packet.answers[1].cls)
      assert_equal(3599, packet.answers[1].ttl)
      assert_equal("ns19.domaincontrol.com", packet.answers[1].rr.name)

      # Answer: skullsecurity.org.      3599    IN      NS      ns20.domaincontrol.com.
      assert_equal('skullsecurity.org', packet.answers[2].name)
      assert_equal(TYPE_NS, packet.answers[2].type)
      assert_equal(CLS_IN, packet.answers[2].cls)
      assert_equal(3599, packet.answers[2].ttl)
      assert_equal("ns20.domaincontrol.com", packet.answers[2].rr.name)

      # Answer: skullsecurity.org.      3599    IN      SOA     ns19.domaincontrol.com. dns.jomax.net. 2017030206 28800 7200 604800 3600
      assert_equal('skullsecurity.org', packet.answers[3].name)
      assert_equal(TYPE_SOA, packet.answers[3].type)
      assert_equal(CLS_IN, packet.answers[3].cls)
      assert_equal(3599, packet.answers[3].ttl)
      assert_equal("ns19.domaincontrol.com", packet.answers[3].rr.primary)
      assert_equal("dns.jomax.net", packet.answers[3].rr.responsible)
      assert_equal(2017030206, packet.answers[3].rr.serial)
      assert_equal(28800, packet.answers[3].rr.refresh)
      assert_equal(7200, packet.answers[3].rr.retry_interval)
      assert_equal(604800, packet.answers[3].rr.expire)
      assert_equal(3600, packet.answers[3].rr.ttl)

      # Answer: skullsecurity.org.      3599    IN      MX      5 ALT1.ASPMX.L.GOOGLE.com.
      assert_equal('skullsecurity.org', packet.answers[4].name)
      assert_equal(TYPE_MX, packet.answers[4].type)
      assert_equal(CLS_IN, packet.answers[4].cls)
      assert_equal(3599, packet.answers[4].ttl)
      assert_equal("ALT1.ASPMX.L.GOOGLE.com", packet.answers[4].rr.name)
      assert_equal(5, packet.answers[4].rr.preference)

      # Answer: skullsecurity.org.      3599    IN      MX      5 ALT2.ASPMX.L.GOOGLE.com.
      assert_equal('skullsecurity.org', packet.answers[5].name)
      assert_equal(TYPE_MX, packet.answers[5].type)
      assert_equal(CLS_IN, packet.answers[5].cls)
      assert_equal(3599, packet.answers[5].ttl)
      assert_equal("ALT2.ASPMX.L.GOOGLE.com", packet.answers[5].rr.name)
      assert_equal(5, packet.answers[5].rr.preference)

      # Answer: skullsecurity.org.      3599    IN      MX      10 ASPMX2.GOOGLEMAIL.com.
      assert_equal('skullsecurity.org', packet.answers[6].name)
      assert_equal(TYPE_MX, packet.answers[6].type)
      assert_equal(CLS_IN, packet.answers[6].cls)
      assert_equal(3599, packet.answers[6].ttl)
      assert_equal("ASPMX2.GOOGLEMAIL.com", packet.answers[6].rr.name)
      assert_equal(10, packet.answers[6].rr.preference)

      # Answer: skullsecurity.org.      3599    IN      MX      10 ASPMX3.GOOGLEMAIL.com.
      assert_equal('skullsecurity.org', packet.answers[7].name)
      assert_equal(TYPE_MX, packet.answers[7].type)
      assert_equal(CLS_IN, packet.answers[7].cls)
      assert_equal(3599, packet.answers[7].ttl)
      assert_equal("ASPMX3.GOOGLEMAIL.com", packet.answers[7].rr.name)
      assert_equal(10, packet.answers[7].rr.preference)

      # Answer: skullsecurity.org.      3599    IN      MX      1 ASPMX.L.GOOGLE.com.
      assert_equal('skullsecurity.org', packet.answers[8].name)
      assert_equal(TYPE_MX, packet.answers[8].type)
      assert_equal(CLS_IN, packet.answers[8].cls)
      assert_equal(3599, packet.answers[8].ttl)
      assert_equal("ASPMX.L.GOOGLE.com", packet.answers[8].rr.name)
      assert_equal(1, packet.answers[8].rr.preference)

      # Answer: skullsecurity.org.      3599    IN      TXT     "google-site-verification=uIcBFvNXSSaAEIkg6kZ3_ZLAVpCnAmI3PIuIzwrbpv8"
      assert_equal('skullsecurity.org', packet.answers[9].name)
      assert_equal(TYPE_TXT, packet.answers[9].type)
      assert_equal(CLS_IN, packet.answers[9].cls)
      assert_equal(3599, packet.answers[9].ttl)
      assert_equal("google-site-verification=uIcBFvNXSSaAEIkg6kZ3_ZLAVpCnAmI3PIuIzwrbpv8", packet.answers[9].rr.data)

      # Answer: skullsecurity.org.      3599    IN      TXT     "oh hai NSA"
      assert_equal('skullsecurity.org', packet.answers[10].name)
      assert_equal(TYPE_TXT, packet.answers[10].type)
      assert_equal(CLS_IN, packet.answers[10].cls)
      assert_equal(3599, packet.answers[10].ttl)
      assert_equal("oh hai NSA", packet.answers[10].rr.data)
    end

    def test_parse_real_error()
      # Generated with `dig @8.8.8.8 -t A fake.skullsecurity.org`, which doesn't
      # exist right now, but it's the kind of thing I might create in the future
      # so YMMV :)
      response = "\x9b\xe6\x81\x83\x00\x01\x00\x00\x00\x01\x00\x01\x04\x66\x61\x6b" +
        "\x65\x0d\x73\x6b\x75\x6c\x6c\x73\x65\x63\x75\x72\x69\x74\x79\x03" +
        "\x6f\x72\x67\x00\x00\x01\x00\x01\xc0\x11\x00\x06\x00\x01\x00\x00" +
        "\x07\x07\x00\x3b\x04\x6e\x73\x31\x39\x0d\x64\x6f\x6d\x61\x69\x6e" +
        "\x63\x6f\x6e\x74\x72\x6f\x6c\x03\x63\x6f\x6d\x00\x03\x64\x6e\x73" +
        "\x05\x6a\x6f\x6d\x61\x78\x03\x6e\x65\x74\x00\x78\x39\x70\x3e\x00" +
        "\x00\x70\x80\x00\x00\x1c\x20\x00\x09\x3a\x80\x00\x00\x0e\x10\x00" +
        "\x00\x29\x02\x00\x00\x00\x00\x00\x00\x00"
      packet = Packet.parse(response)

      assert_equal(0x9be6, packet.trn_id)
      assert_equal(QR_RESPONSE, packet.qr)
      assert_equal(OPCODE_QUERY, packet.opcode)
      assert_equal(FLAG_RD | FLAG_RA, packet.flags)
      assert_equal(RCODE_NAME_ERROR, packet.rcode)

      assert_equal('fake.skullsecurity.org', packet.questions[0].name)
      assert_equal(TYPE_A, packet.questions[0].type)
      assert_equal(CLS_IN, packet.questions[0].cls)
    end

    def test_answer()
      request = "\x8d\xbe\x01\x20\x00\x01\x00\x00\x00\x00\x00\x01\x0d\x73\x6b\x75" +
        "\x6c\x6c\x73\x65\x63\x75\x72\x69\x74\x79\x03\x6f\x72\x67\x00\x00" +
        "\x01\x00\x01\x00\x00\x29\x10\x00\x00\x00\x00\x00\x00\x00"

      packet = Packet.parse(request)
      response = packet.answer(answers: [
        Answer.new(name: 'google.com', type: TYPE_A, cls: CLS_IN, ttl: 0x12345678, rr: A.new(address: '1.2.3.4')),
      ])

      assert_equal(0x8dbe, response.trn_id)
      assert_equal(QR_RESPONSE, response.qr)
      assert_equal(OPCODE_QUERY, response.opcode)
      assert_equal(FLAG_RD | FLAG_RA, response.flags)
      assert_equal(RCODE_SUCCESS, response.rcode)

      # Echoing back the question
      assert_equal('skullsecurity.org', response.questions[0].name)
      assert_equal(TYPE_A, response.questions[0].type)
      assert_equal(CLS_IN, response.questions[0].cls)

      # Answer: skullsecurity.org.      3599    IN      A       192.155.81.86
      assert_equal('google.com', response.answers[0].name)
      assert_equal(TYPE_A, response.answers[0].type)
      assert_equal(CLS_IN, response.answers[0].cls)
      assert_equal(0x12345678, response.answers[0].ttl)
      assert_equal(IPAddr.new('1.2.3.4'), response.answers[0].rr.address)
    end

    def test_create_error_response()
      request = "\x8d\xbe\x01\x20\x00\x01\x00\x00\x00\x00\x00\x01\x0d\x73\x6b\x75" +
        "\x6c\x6c\x73\x65\x63\x75\x72\x69\x74\x79\x03\x6f\x72\x67\x00\x00" +
        "\x01\x00\x01\x00\x00\x29\x10\x00\x00\x00\x00\x00\x00\x00"

      packet = Packet.parse(request)
      response = packet.error(rcode: RCODE_NAME_ERROR)

      assert_equal(0x8dbe, response.trn_id)
      assert_equal(QR_RESPONSE, response.qr)
      assert_equal(OPCODE_QUERY, response.opcode)
      assert_equal(FLAG_RD | FLAG_RA, response.flags)
      assert_equal(RCODE_NAME_ERROR, response.rcode)

      # Echoing back the question
      assert_equal('skullsecurity.org', response.questions[0].name)
      assert_equal(TYPE_A, response.questions[0].type)
      assert_equal(CLS_IN, response.questions[0].cls)
    end

    def test_asserts()
      packet = Packet.new(trn_id:0x1337, qr:QR_QUERY, opcode:OPCODE_QUERY, flags:FLAG_RD, rcode:RCODE_SUCCESS, questions:[], answers:[])
      assert_raises(DnsException) do
        packet.add_question("hi")
      end
      assert_raises(DnsException) do
        packet.add_answer("hi")
      end
    end
  end
end
