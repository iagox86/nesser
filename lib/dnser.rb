# Encoding: ASCII-8BIT
##
# dnser.rb
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
# To make a query, use DNSer.query:
#
#   DNSer.query("google.com") do |response|
#     ...
#   end
#
# `response` will be of type DNSer::Packet.
#
# To listen for queries, create a new instance of DNSer, which will begin
# listening on a port, but won't actually handle queries yet:
#
#   dnser = DNSer.new("0.0.0.0", 53) do |transaction|
#     ...
#   end
#
# `transaction` is of type DNSer::Transaction, and allows you to respond to the
# request either immediately or asynchronously.
#
# DNSer currently supports the following record types: A, NS, CNAME, SOA, MX,
# TXT, and AAAA.
##

require 'ipaddr'
require 'socket'
require 'timeout'

require "dnser/version"

module DNSer
  class DNSer
    attr_reader :thread

    def initialize(s:, logger:, host:"0.0.0.0", port:53)
      @s = s
      @s.bind(host, port)
      @logger = logger

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
            end

            # Create a transaction object, which we can use to respond
            transaction = Transaction.new(
              s: @s,
              request_packet: request,
              host: data[1][3],
              port: data[1][1],
            )

            begin
              proc.call(transaction)
            rescue StandardError => e
              logger.error("Error thrown while processing the DNS packet: %s" % e.to_s())
              logger.info(e.backtrace())
              transaction.error!(RCODE_SERVER_FAILURE)
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
        @logger.error("Tried to wait on a DNSer instance that wasn't listening!")
        return
      end

      @thread.join()
    end

    # Send out a query, asynchronously. This immediately returns, then, when the
    # query is finished, the callback block is called with a DNSer::Packet that
    # represents the response (or nil, if there was a timeout).
    def DNSer.query(s, hostname, params = {})
      server   = params[:server]   || "8.8.8.8"
      port     = params[:port]     || 53
      type     = params[:type]     || DNSer::Packet::TYPE_A
      cls      = params[:cls]      || DNSer::Packet::CLS_IN
      timeout  = params[:timeout]  || 3

      packet = DNSer::Packet.new(rand(65535), DNSer::Packet::QR_QUERY, DNSer::Packet::OPCODE_QUERY, DNSer::Packet::FLAG_RD, DNSer::Packet::RCODE_SUCCESS)
      packet.add_question(DNSer::Packet::Question.new(hostname, type, cls))

      s = UDPSocket.new()

      return Thread.new() do
        begin
          s.send(packet.serialize(), 0, server, port)

          timeout(timeout) do
            response = s.recv(65536)
            proc.call(DNSer::Packet.unpack(response))
          end
        rescue Timeout::Error
          proc.call(nil)
        rescue Exception => e
          @logger.error("There was an exception sending a query for #{hostname} to #{server}:#{port}: #{e}")
        ensure
          if(s)
            s.close()
          end
        end
      end
    end
  end
end
