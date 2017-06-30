# Encoding: ASCII-8BIT
##
# unpacker.rb
# Created June 20, 2017
# By Ron Bowes
#
# See: LICENSE.md
#
# DNS has some unusual properties that we have to handle, which is why I
# wrote this class. It handles building / parsing DNS packets and keeping
# track of where in the packet we currently are. The advantage, besides
# simpler unpacking, is that encoded names (with pointers to other parts
# of the packet) can be trivially handled.
##

require 'hexhelper'

require 'nesser/dns_exception'
require 'nesser/packets/constants'

module Nesser
  class Unpacker
    attr_accessor :data, :offset

    public
    def initialize(data)
      @data = data
      @offset = 0
    end

    private
    def _verify_results(results)
      # If there's at least one nil included in our results, bad stuff happened
      if results.index(nil)
        raise(FormatException, "DNS packet was truncated (or we messed up parsing it)!")
      end
    end

    # Unpack from the string, exactly like the normal `String#Unpack` method
    # in Ruby, except that an offset into the string is maintained and updated.
    public
    def unpack(format)
      if @offset >= @data.length
        raise(FormatException, "DNS packet was invalid!")
      end

      results = @data[@offset..-1].unpack(format + "a*")
      remaining = results.pop
      @offset = @data.length - remaining.length

      _verify_results(results)

      return *results
    end

    public
    def unpack_one(format)
      results = unpack(format)

      _verify_results(results)
      if results.length != 1
        raise(FormatException, "unpack_one() was passed a bad format string")
      end

      return results.pop()
    end

    # This temporarily changes the offset that we're reading from, runs the
    # given block, then changes it back. This is used internally while
    # unpacking names.
    private
    def _with_offset(offset)
      old_offset = @offset
      @offset = offset
      yield
      @offset = old_offset
    end

    # Unpack a name from the packet. Names are special, because they're
    # encoded as:
    # * A series of length-prefixed blocks, each indicating a segment
    # * Blocks with a length the starts with two '1' bits (11xxxxx...), which
    #   contains a pointer to another name elsewhere in the packet
    public
    def unpack_name(depth:0)
      segments = []

      if depth > MAX_RECURSION_DEPTH
        raise(FormatException, "It looks like this packet contains recursive pointers!")
      end

      loop do
        # If no offset is given, just eat data from the normal source
        len = unpack_one("C")

        # Stop at the null terminator
        if len == 0
          break
        end

        # Handle "pointer" records by updating the offset
        if (len & 0xc0) == 0xc0
          # If the first two bits are 1 (ie, 0xC0), the next
          # 10 bits are an offset, so we have to mask out the first two bits
          # with 0x3F (00111111)
          offset = ((len << 8) | unpack_one("C")) & 0x3FFF

          _with_offset(offset) do
            segments << unpack_name(depth:depth+1).split(/\./)
          end

          break
        end

        # It's normal, just unpack what we need to!
        segments << unpack("a#{len}")
      end

      return segments.join('.')
    end

    public
    def to_s()
      return HexHelper::to_s(@data, offset: @offset)
    end
  end
end
