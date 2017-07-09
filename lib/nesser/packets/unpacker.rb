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

    ##
    # Create a new unpacker with a string (the string must be the full DNS
    # request, starting at the `trn_id` - otherwise, unpacking compressed
    # fields won't work properly!
    ##
    public
    def initialize(data)
      @data = data
      @offset = 0
    end

    ##
    # Does some basic error checking to make sure we didn't run off the end of
    # packet - doesn't catch every case, though.
    ##
    private
    def _verify_results(results)
      # If there's at least one nil included in our results, bad stuff happened
      if results.index(nil)
        raise(DnsException, "DNS packet was truncated (or we messed up parsing it)!")
      end
    end

    ##
    # Unpack from the string, exactly like the normal `String.unpack()` method
    # in Ruby, except that a pointer offset into the string is maintained and
    # updated (which is required for unpacking names).
    ##
    public
    def unpack(format)
      if @offset >= @data.length
        raise(DnsException, "DNS packet was invalid!")
      end

      results = @data[@offset..-1].unpack(format + "a*")
      remaining = results.pop
      @offset = @data.length - remaining.length

      _verify_results(results)

      return *results
    end

    ##
    # Unpack a single element from the buffer and return it (this is a simple
    # little utility function that I wrote to save myself time).
    #
    # The `format` argument works exactly like in `String.unpack()`, but only
    # one element can be given.
    ##
    public
    def unpack_one(format)
      results = unpack(format)

      _verify_results(results)
      if results.length != 1
        raise(DnsException, "unpack_one() was passed a bad format string")
      end

      return results.pop()
    end

    ##
    # Temporarily changes the offset that we're reading from, runs the given
    # block, then changes it back. This is used internally while unpacking names.
    ##
    private
    def _with_offset(offset)
      old_offset = @offset
      @offset = offset
      yield
      @offset = old_offset
    end

    ##
    # Unpack a name from the packet and convert it into a standard dotted name
    # that we all understand.
    #
    # At the simplest, names are encoded as length-prefixed blocks. For example,
    # "google.com" is encoded as "\x06google\x03com\x00".
    #
    # More complex, however, is that all or part of a name can be replaced with
    # "\xc0" followed by an offset into the packet where the remainder of the
    # name (or the full name) can be found. For example, if
    # "\x06google\x03com\x00" is found at index 0x0c (which it frequently is),
    # then "www.google.com" can be encoded as "\x03www\xc0\x0c". In other words,
    # "www" followed by the rest of the name at offset 0x0c".
    #
    # The point of this class is that that situation is handled as cleanly as
    # possible.
    #
    # The `depth` argument is used internally for recursion, the default value
    # of 0 should be used externally.
    ##
    public
    def unpack_name(depth:0)
      segments = []

      if depth > MAX_RECURSION_DEPTH
        raise(DnsException, "It looks like this packet contains recursive pointers!")
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
