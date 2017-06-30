# Encoding: ASCII-8BIT
##
# dns_exception.rb
# Created June 20, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# Implements a simple exception class for dns errors.
##

module DNSer
  class DnsException < StandardError
  end

  class FormatException < DnsException
  end
end
