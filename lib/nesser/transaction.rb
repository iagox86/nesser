# Encoding: ASCII-8BIT
##
# transaction.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# When a request comes in, a transaction is created and sent to the callback.
# The transaction can be used to respond to the request at any point in the
# future.
#
# Any methods with a bang ('!') in front will send the response back to the
# requester. Only one bang method can be called, any subsequent calls will
# throw an exception.
##
module Nesser
  class Transaction
    attr_reader :request, :sent
    attr_accessor :response

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
        raise ArgumentError("Already sent!")
      end
    end

    public
    def open?()
      return !@sent
    end

    public
    def answer!(answers=[])
      answers.each do |answer|
        @response.add_answer(answer)
      end

      reply!()
    end

    public
    def error!(rcode)
      not_sent!()

      @response.rcode = rcode
      reply!()
    end

#    public
#    def passthrough!(pt_host, pt_port, callback = nil)
#      not_sent!()
#
#      Nesser.query(@request.questions[0].name, {
#          :server  => pt_host,
#          :port    => pt_port,
#          :type    => @request.questions[0].type,
#          :cls     => @request.questions[0].cls,
#          :timeout => 3,
#        }
#      ) do |response|
#        # If there was a timeout, handle it
#        if(response.nil?)
#          response = @response
#          response.rcode = Nesser::Packet::RCODE_SERVER_FAILURE
#        end
#
#        response.trn_id = @request.trn_id
#        @s.send(response.serialize(), 0, @host, @port)
#
#        # Let the callback know if anybody registered one
#        if(callback)
#          callback.call(response)
#        end
#      end
#
#      @sent = true
#    end

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

      return result.join("\n")
    end
  end
end
