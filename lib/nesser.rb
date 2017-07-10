# Encoding: ASCII-8BIT
##
# nesser.rb
# Created Oct 7, 2015
# By Ron Bowes
#
# See: LICENSE.md
#
# I had nothing but trouble using rubydns (which became celluloid-dns, whose
# documentation is just flat out wrong), and I only really need a very small
# subset of DNS functionality, so I decided that I should just wrote my own.
#
# Note: after writing this, I noticed that Resolv::DNS exists in the Ruby
# language, I need to check if I can use that.
#
# There are two methods for using this library: as a client (to make a query)
# or as a server (to listen for queries and respond to them).
#
# To avoid putting too much narrative in this header, I wrote full usage
# details in README.md in the root directory. Check that out for full usage
# details!
##

require 'ipaddr'
require 'socket'
require 'timeout'

require 'nesser/version'

require 'nesser/packets/packet'
require 'nesser/transaction'
require 'nesser/logger'

module Nesser
  class Nesser
    attr_reader :thread

    ##
    # Create a new instance and start listening for requests in a new thread.
    # Returns instantly (use the `wait()` method to pause until the thread is
    # over (pretty much indefinitely).
    #
    # The `s` parameter should be an instance of `UDPSocket` in `socket`. The
    # logger will default to an instance of `Nesser::Logger` if it's not
    # specified, which simply logs to stdout.
    #
    # The other parameters are reasonably self explanatory.
    #
    # When you create an instance, you must also specify a proc:
    #
    # ```ruby
    # Nesser::Nesser.new(s: s) do |transaction|
    #   # ...
    # end
    # ```
    #
    # Whenever a valid DNS message comes in, a new `Nesser::Transaction` is
    # created and the proc is called with it (an invalid packet will be printed
    # to the logger and discarded). It's up to the user to answer it using
    # `transaction.answer!()`, `transaction.error!()`, etc. (see README.md for
    # examples).
    #
    # If the handler function throws an Exception (most non-system errors),
    # a SERVFAIL message will be returned automatically and the error will be
    # logged to the logger.
    ##
    def initialize(s:, logger: nil, host:"0.0.0.0", port:53)
      @s = s
      @s.bind(host, port)

      @logger = (logger = logger || Logger.new())

      @thread = Thread.new() do
        loop do
          # Grab all the data we can off the socket
          data = @s.recvfrom(65536)

          begin
            # Data is an array where the first element is the actual data, and the second is the host/port
            request = Packet.parse(data[0])
          rescue DnsException => e
            logger.error("Failed to parse the DNS packet: %s" % e.to_s())
            next
          rescue Exception => e
            logger.error("Error: %s" % e.to_s())
            logger.info(e.backtrace().join("\n"))
          end

          # Create a transaction object, which we can use to respond
          transaction = Transaction.new(
            s: @s,
            request: request,
            host: data[1][3],
            port: data[1][1],
          )

          begin
            proc.call(transaction)
          rescue StandardError => e
            logger.error("Error thrown while processing the DNS packet: %s" % e.to_s())
            logger.info(e.backtrace().join("\n"))

            if transaction.open?()
              transaction.error!(RCODE_SERVER_FAILURE)
            end
          end
        end
      end
    end

    ##
    # Kill the listener thread (once this is called, the class instance is
    # worthless).
    ##
    def stop()
      if(@thread.nil?)
        @logger.error("Tried to stop a listener that wasn't listening!")
        return
      end

      @thread.kill()
      @thread = nil
    end

    ##
    # Pauses as long as the listener thread is alive (generally, that means
    # indefinitely).
    ##
    def wait()
      if(@thread.nil?)
        @logger.error("Tried to wait on a Nesser instance that wasn't listening!")
        return
      end

      @thread.join()
    end

    ##
    # Send a query.
    #
    # * `s`: an instance of `UDPSocket` from 'socket'.
    # * `hostname`: the name being queried - eg, 'example.org'.
    # * `server` and `port`: The upstream DNS server to query.
    # * `type` and `cls`: typical DNS values, you can find a list of them in
    #    packets/constants.rb.
    # * `timeout`: The number of seconds to wait for a response before giving up.
    #
    # Returns a Nesser::Packet (nesser/packets/packet.rb).
    ##
    def self.query(s:, hostname:, server: '8.8.8.8', port: 53, type: TYPE_A, cls: CLS_IN, timeout: 3)
      s = UDPSocket.new()

      question = Question.new(
        name: hostname,
        type: type,
        cls: cls,
      )

      packet = Packet.new(
        trn_id: rand(65535),
        qr: QR_QUERY,
        opcode: OPCODE_QUERY,
        flags: FLAG_RD,
        rcode: RCODE_SUCCESS,
        questions: [question],
        answers: [],
      )

      begin
        Timeout.timeout(timeout) do
          s.send(packet.to_bytes(), 0, server, port)
          response = s.recv(65536)

          if response.nil?()
            raise(DnsException, "Error communicating with the DNS server")
          end

          return Packet.parse(response)
        end
      rescue Timeout::Error
        raise(DnsException, "Timeout communicating with the DNS server")
      end
    end
  end
end
