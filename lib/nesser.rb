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
# To make a query, use Nesser.query:
#
# ...TODO...
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

    def initialize(s:, logger: nil, host:"0.0.0.0", port:53)
      @s = s
      @s.bind(host, port)

      @logger = (logger = logger || Logger.new())

      @thread = Thread.new() do
        begin
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
        ensure
          @s.close()
        end
      end
    end

    # Kill the listener
    def stop()
      if(@thread.nil?)
        @logger.error("Tried to stop a listener that wasn't listening!")
        return
      end

      @thread.kill()
      @thread = nil
    end

    # After calling on_request(), this can be called to halt the program's
    # execution until the thread is stopped.
    def wait()
      if(@thread.nil?)
        @logger.error("Tried to wait on a Nesser instance that wasn't listening!")
        return
      end

      @thread.join()
    end

    # Send out a query
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
