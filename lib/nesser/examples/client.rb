# Encoding: ASCII-8BIT
##
# client.rb
# Created July 8, 2017
# By Ron Bowes
#
# See: LICENSE.md
##

# If you're using a gem version, you wouldn't need this line
$LOAD_PATH.unshift File.expand_path('../../../', __FILE__)

require 'socket'
require 'nesser'

# Create a UDP socket
s = UDPSocket.new()

# Perform a query for 'google.com', of type ANY. I chose this because it has a
# wide array of varied answers.
#
# See packets/constants.rb for a full list of possible request types.
result = Nesser::Nesser.query(s: s, hostname: 'google.com', type: Nesser::TYPE_ANY)

# Print the result
puts result
