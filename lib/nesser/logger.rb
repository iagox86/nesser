# Encoding: ASCII-8BIT
##
# dns_exception.rb
# Created June 20, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# Implements a simple exception class for dns errors.
##

module Nesser
  class Logger
    DEBUG   = 0
    INFO    = 1
    WARNING = 2
    ERROR   = 3
    FATAL   = 4

    def initialize(min_level: INFO, stream: IO::STDERR)
      @min_level = min_level
      @stream = stream
    end

    def debug(msg)
      return if min_level > DEBUG
      $stream.puts('[DEBUG] ' + msg)
    end

    def info(msg)
      return if min_level > INFO
      $stream.puts('[INFO] ' + msg)
    end

    def warning(msg)
      return if min_level > WARNING
      $stream.puts('[WARNING] ' + msg)
    end

    def error(msg)
      return if min_level > ERROR
      $stream.puts('[ERROR] ' + msg)
    end

    def fatal(msg, die: false)
      return if min_level > FATAL
      $stream.puts('[FATAL] ' + msg)

      exit() if die
    end
  end
end
