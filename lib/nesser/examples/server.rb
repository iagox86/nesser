# Encoding: ASCII-8BIT
##
# server.rb
# Created July 8, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

# If you're using a gem version, you wouldn't need this line
$LOAD_PATH.unshift File.expand_path('../../../', __FILE__)

require 'socket'
require 'nesser'

s = UDPSocket.new()

nesser = Nesser::Nesser.new(s: s) do |transaction|
  if transaction.request_packet.questions[0].name == 'test.com'
    transaction.answer!([Nesser::Answer.new(
      name: 'test.com',
      type: Nesser::TYPE_A,
      cls: Nesser::CLS_IN,
      ttl: 1337,
      rr: Nesser::A.new(address: '1.2.3.4')
    )])
  else
    transaction.error!(Nesser::RCODE_NAME_ERROR)
  end
  puts(transaction)
end

nesser.wait()
