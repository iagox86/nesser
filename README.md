# Nesser

A DNS client and server class, written for Dnscat2 (and other similar projects).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nesser'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nesser

## Usage

### Client

After installing the gem, using it as a client is pretty straight forward.
I wrote an example file in [lib/nesser/examples](lib/nesser/examples), but in
a nutshell, here's the code:

    require 'nesser'
    
    s = UDPSocket.new()
    result = Nesser::Nesser.query(s: s, hostname: 'google.com', type: Nesser::TYPE_ANY)

You can find all constant definitions in
[the constants.rb file](lib/nesser/packets/constants.rb)

The return from Nesser.query() is an instance of
[Nesser::Answer](lib/nesser/packets/answer.rb).

### Server

TODO

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iagox86/nesser

