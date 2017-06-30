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
module DNSer
  class Transaction
    attr_reader :request_packet, :response_packet, :sent

    public
    def initialize(s:, request_packet:, host:, port:)
      @s = s
      @request_packet = request_packet
      @host = host
      @port = port
      @sent = false

      @response_packet = request_packet.answer()
    end

    private
    def not_sent!()
      if @sent
        raise ArgumentError("Already sent!")
      end
    end

    public
    def answer!(answers=[])
      answers.each do |answer|
        @response_packet.add_answer(answer)
      end

      reply!()
    end

    public
    def error!(rcode)
      not_sent!()

      @response_packet.rcode = rcode
      reply!()
    end

#    public
#    def passthrough!(pt_host, pt_port, callback = nil)
#      not_sent!()
#
#      DNSer.query(@request.questions[0].name, {
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
#          response.rcode = DNSer::Packet::RCODE_SERVER_FAILURE
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

    private
    def reply!()
      not_sent!()

      @s.send(@response_packet.to_bytes(), 0, @host, @port)
      @sent = true
    end
  end
end
