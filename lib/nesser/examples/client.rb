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

s = UDPSocket.new()
puts Nesser::Nesser.query(s: s, hostname: 'google.com', type: Nesser::TYPE_ANY)
