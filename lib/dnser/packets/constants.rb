# Encoding: ASCII-8BIT
##
# constants.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

module DNSer
  # Max recursion depth for parsing names
  MAX_RECURSION_DEPTH = 16

  # These restrictions are from RFC 952
  LEGAL_CHARACTERS = (
    ('a'..'z').to_a +
    ('A'..'Z').to_a +
    (0..9).to_a +
    ['-', '.']
  )
  MAX_SEGMENT_LENGTH = 63
  MAX_TOTAL_LENGTH = 253

  CLS_IN                = 0x0001 # Internet
  CLSES = {
    CLS_IN => "IN",
  }

  # Request / response
  QR_QUERY    = 0x0000
  QR_RESPONSE = 0x0001

  QRS = {
    QR_QUERY    => "QUERY",
    QR_RESPONSE => "RESPONSE",
  }

  # Return codes
  RCODE_SUCCESS         = 0x0000
  RCODE_FORMAT_ERROR    = 0x0001
  RCODE_SERVER_FAILURE  = 0x0002 # :servfail
  RCODE_NAME_ERROR      = 0x0003 # :NXDomain
  RCODE_NOT_IMPLEMENTED = 0x0004
  RCODE_REFUSED         = 0x0005

  RCODES = {
    RCODE_SUCCESS         => ":NoError (RCODE_SUCCESS)",
    RCODE_FORMAT_ERROR    => ":FormErr (RCODE_FORMAT_ERROR)",
    RCODE_SERVER_FAILURE  => ":ServFail (RCODE_SERVER_FAILURE)",
    RCODE_NAME_ERROR      => ":NXDomain (RCODE_NAME_ERROR)",
    RCODE_NOT_IMPLEMENTED => ":NotImp (RCODE_NOT_IMPLEMENTED)",
    RCODE_REFUSED         => ":Refused (RCODE_REFUSED)",
  }

  # Opcodes - only QUERY is typically used
  OPCODE_QUERY  = 0x0000
  OPCODE_IQUERY = 0x0800
  OPCODE_STATUS = 0x1000

  OPCODES = {
    OPCODE_QUERY  => "OPCODE_QUERY",
    OPCODE_IQUERY => "OPCODE_IQUERY",
    OPCODE_STATUS => "OPCODE_STATUS",
  }

  # The types that we support
  TYPE_A     = 0x0001
  TYPE_NS    = 0x0002
  TYPE_CNAME = 0x0005
  TYPE_SOA   = 0x0006
  TYPE_MX    = 0x000f
  TYPE_TXT   = 0x0010
  TYPE_AAAA  = 0x001c
  TYPE_ANY   = 0x00FF

  TYPES = {
    TYPE_A     => "A",
    TYPE_NS    => "NS",
    TYPE_CNAME => "CNAME",
    TYPE_SOA   => "SOA",
    TYPE_MX    => "MX",
    TYPE_TXT   => "TXT",
    TYPE_AAAA  => "AAAA",
    TYPE_ANY   => "ANY",
  }

  # The DNS flags
  FLAG_AA = 0x0008 # Authoritative answer
  FLAG_TC = 0x0004 # Truncated
  FLAG_RD = 0x0002 # Recursion desired
  FLAG_RA = 0x0001 # Recursion available

  # This converts a set of flags, as an integer, into a string
  def self.FLAGS(flags)
    result = []
    if((flags & FLAG_AA) == FLAG_AA)
      result << "AA"
    end
    if((flags & FLAG_TC) == FLAG_TC)
      result << "TC"
    end
    if((flags & FLAG_RD) == FLAG_RD)
      result << "RD"
    end
    if((flags & FLAG_RA) == FLAG_RA)
      result << "RA"
    end

    return result.join("|")
  end
end
