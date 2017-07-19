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

    ##
    # This is simply a wrapper around String.pack() - it's for packing perfectly
    # ordinary data into a DNS packet.
    ##
    public
    def pack(format, *data)
      @data += data.pack(format)
    end

    ##
    # Sanity check a name (length, legal characters, etc).
    ##
    private
    def validate!(name)
      if name.chars.detect { |ch|
        if(!LEGAL_CHARACTERS.include?(ch))
          puts ch;
          return false;
        end
        return true;
      }
        raise(DnsException, "DNS name contains illegal characters (%s)" % name)
      end
      if name.length > 253
        raise(DnsException, "DNS name can't be longer than 253 characters")
      end
      name.split(/\./).each do |segment|
        if segment.length == 0 || segment.length > 63
          raise(DnsException, "DNS segments must be between 1 and 63 characters!")
        end
      end
    end

    ##
    # This function is sort of the point of this class's existance.
    #
    # You pass in a typical DNS name, such as "google.com". If that name
    # doesn't appear in the packet yet, it's simply encoded with length-
    # prefixed segments - "\x06google\x03com\x00".
    #
    # However, if all or part of the name already exist in the packet, this will
    # save packet space by re-using those segments. For example, let's say that
    # "google.com" exists 0x0c bytes into the packet (which it normally does).
    # In that case, instead of including "\x06google\x03com\x00" a second time,
    # it will simply encode the offset with "\xc0" in front - "\xc0\x0c".
    #
    # Let's say that later in the packet, we have "www.google.com". That string
    # as a whole hasn't appeared yet, but "google.com" appeared at offset 0x0c.
    # It will then be encoded "\x03www\xc0\x0c" - the longest possible segment
    # is encoded.
    #
    # This logic is somewhat complicated, but this function seems to work
    # pretty well. :)
    #
    # * `name`: The name to encode, as a normal dotted string.
    # * `dry_run`: If set to true, don't actually "write" the name. This is
    #   unfortunately needed to check the size of something that *would* be
    #   encoded, since we occasionally need the length written to the buffer
    #   before the name.
    # * `compress`: If set (which it always probably should be), will attempt
    #   to do the compression ("\xc0") stuff discussed earlier.
    #
    # Returns the actual length of the name.
    ##
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

    ##
    # Retrieve the buffer as a string.
    ##
    public
    def get()
      return @data
    end
  end
end
