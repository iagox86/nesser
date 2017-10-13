# Encoding: ASCII-8BIT
##
# transaction.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# When a request comes in, a transaction is created to represent it. The
# transaction can be used to respond to the request at any point in the
# future - the trn_id and socket and stuff are all set up. Though, keep in
# mind, most clients will only wait like 3 seconds, so responding at *any*
# point, while technically true, isn't really a useful distinction.
#
# Any methods with a bang ('!') in their name will send the response back to the
# requester. Only one bang method can be called, any subsequent calls will
# throw an exception.
#
# You'll almost always want to use either `transaction.answer!()` or
# `transaction.error!()`. While it's possible to change and/or add to
# `transaction.response` and send it with `transaction.reply!()`, that's more
# complex and generally not needed.
##

require 'socket'

module Nesser
  class Transaction
    attr_reader :request, :sent
    attr_accessor :response

    ##
    # Create a new instance of Transaction. This is used internally - it's
    # unlikely you'll ever need to create an instance.
    ##
    public
    def initialize(s:, request:, host:, port:)
      @s = s
      @request = request
      @host = host
      @port = port
      @sent = false

      @response = request.answer()
    end

    private
    def not_sent!()
      if @sent
        # TODO: This isn't a valid raise
        raise ArgumentError("Already sent!")
      end
    end

    ##
    # Check whether or not the transaction has been sent already.
    ##
    public
    def open?()
      return !@sent
    end

    ##
    # Reply with zero or more answers, specified in the array.
    #
    # Only one "bang function" can be called per transaction, subsequent calls
    # will throw an exception.
    ##
    public
    def answer!(answers=[])
      answers.each do |answer|
        @response.add_answer(answer)
      end

      reply!()
    end

    ##
    # Reply with an error defined by rcode (you can find a full list in
    # packets/constants.rb).
    #
    # Only one "bang function" can be called per transaction, subsequent calls
    # will throw an exception.
    ##
    public
    def error!(rcode)
      not_sent!()

      @response.rcode = rcode
      reply!()
    end

    ##
    # Send the request upstream.
    #
    # Note that this requires a socket, and that it can't be the same socket
    # as the rest of the transaction (since we don't do any kind of
    # multiplexing). If you don't specify a socket, one will be provided to
    # you at no extra cost (financially, anyways).
    ##
    public
    def passthrough!(host:'8.8.8.8', port:53)
      not_sent!()

      # Get a local handle to the socket
      s = @s

      Thread.new() do
        begin
          response = Nesser.query(
            s: s,
            hostname: @request.questions[0].name,
            server: host,
            port: port,
            type: @request.questions[0].type,
            cls: @request.questions[0].cls,
          )

          if response.rcode != RCODE_SUCCESS
            error!(response.rcode)
          else
            answer!(response.answers)
          end
        rescue StandardError
          error!(RCODE_SERVER_FAILURE)
        end
      end
    end

    ##
    # Reply with the response packet, in whatever state it's in. While this is
    # public and gives you find control over the packet being sent back,
    # realistically answer!() and error!() are probably all you'll need. Only
    # use this is those won't work for whatever reason.
    #
    # Only one "bang function" can be called per transaction, subsequent calls
    # will throw an exception.
    public
    def reply!()
      not_sent!()

      @s.send(@response.to_bytes(), 0, @host, @port)
      @sent = true
    end

    public
    def to_s()
      result = []

      result << '== Nesser (DNS) Transaction =='
      result << '-- Request --'
      result << @request.to_s()
      if !sent()
        result << '-- Response [not sent yet] --'
      else
        result << '-- Response [sent] --'
      end
      result << @response.to_s()
      result << ''

      return result.join("\n")
    end
  end
end
