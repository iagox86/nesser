# Encoding: ASCII-8BIT
##
# logger.rb.rb
# Created June 20, 2017
# By Ron Bowes
#
# See LICENSE.md
#
# A super simple logger implementation.
##

module Nesser
  class Logger
    DEBUG   = 0
    INFO    = 1
    WARNING = 2
    ERROR   = 3
    FATAL   = 4

    def initialize(min_level: INFO, stream: STDERR)
      @min_level = min_level
      @stream = stream
    end

    def debug(msg)
      return if @min_level > DEBUG
      @stream.puts('[DEBUG] ' + msg.to_s)
    end

    def info(msg)
      return if @min_level > INFO
      @stream.puts('[INFO] ' + msg.to_s)
    end

    def warning(msg)
      return if @min_level > WARNING
      @stream.puts('[WARNING] ' + msg.to_s)
    end

    def error(msg)
      return if @min_level > ERROR
      @stream.puts('[ERROR] ' + msg.to_s)
    end

    def fatal(msg, die: false)
      return if @min_level > FATAL
      @stream.puts('[FATAL] ' + msg.to_s)

      exit() if die
    end
  end
end
