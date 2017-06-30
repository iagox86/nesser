# Encoding: ASCII-8BIT
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
end

class FakeSocket
  attr_reader :out

  def initialize()
    @out = []
  end

  def send(data, flags, host, port)
    @out << {
      data: data,
      flags: flags,
      host: host,
      port: port,
    }
  end
end

require 'test/unit'
