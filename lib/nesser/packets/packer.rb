# Encoding: ASCII-8BIT
##
# packer.rb
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

require 'nesser/dns_exception'
require 'nesser/packets/constants'

module Nesser
  class Packer
    public
    def initialize()
      @data = ''
      @segment_cache = {}
    end

    public
    def pack(format, *data)
      @data += data.pack(format)
    end

    private
    def validate!(name)
      if name.chars.detect { |ch| !LEGAL_CHARACTERS.include?(ch) }
        raise(FormatException, "DNS name contains illegal characters")
      end
      if name.length > 253
        raise(FormatException, "DNS name can't be longer than 253 characters")
      end
      name.split(/\./).each do |segment|
        if segment.length == 0 || segment.length > 63
          raise(FormatException, "DNS segments must be between 1 and 63 characters!")
        end
      end
    end

    # Take a name, as a dotted string ("google.com") and return it as length-
    # prefixed segments ("\x06google\x03com\x00"). It also does a pointer
    # (\xc0\xXX) when possible!
    public
    def pack_name(name, dry_run:false, compress:true)
      length = 0
      validate!(name)

      # `name` becomes nil at the end, unless there's a comma on the end, in
      # which case it's a 0-length string
      while name and name.length() > 0
        if compress && @segment_cache[name]
          # User a pointer if we've already done this
          if not dry_run
            @data += [0xc000 | @segment_cache[name]].pack("n")
          end

          # If we use break here, we get a bad NUL terminator
          return length + 2
        end

        # Log where we put this segment
        if not dry_run
          @segment_cache[name] = @data.length
        end

        # Get the next label
        segment, name = name.split(/\./, 2)

        # Encode it into the string
        if not dry_run
          @data += [segment.length(), segment].pack("Ca*")
        end
        length += 1 + segment.length()
      end

      # Always be null terminating
      if not dry_run
        @data += "\0"
      end
      length += 1

      return length
    end

    public
    def get()
      return @data
    end
  end
end
