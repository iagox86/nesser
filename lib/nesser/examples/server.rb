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

# Create a UDP socket
s = UDPSocket.new()

# Create a new instance of Nesser to handle transactions
nesser = Nesser::Nesser.new(s: s) do |transaction|
  # We only have an answer for 'test.com' (this is, after all, an example)
  if transaction.request.questions[0].name == 'test.com'
    # Create an A-type resource record pointing to 1.2.3.4. See README.md for
    # details on how to create other record types
    rr = Nesser::A.new(address: '1.2.3.4')

    # Create an answer. The name will almost always be the same as the original
    # name, but the type and cls don't necessarily have to match the request
    # type (in this case, we don't even check what the request type was).
    #
    # You'll probably want the rr's type to match the type: argument. I'm not
    # sure if it'll work otherwise, but the client it's sent to sure as heck
    # won't know what to do with it. :)
    answer = Nesser::Answer.new(
      name: 'test.com',
      type: Nesser::TYPE_A, # See constants.rb for other options
      cls: Nesser::CLS_IN,
      ttl: 1337,
      rr: rr,
    )

    # The transaction's functions that end with '!' actually send the message -
    # in this case, answer!() sends an array of the one answre that we created.
    transaction.answer!([answer])
  else
    # Response NXDomain - aka, no such domain name - to everything other than
    # 'test.com'.
    transaction.error!(Nesser::RCODE_NAME_ERROR)
  end

  # Display the transaction
  puts(transaction)
end

# Since Nesser::Nesser.new() runs in a new thread, we have to basically join
# the thread to prevent the program from ending
nesser.wait()
