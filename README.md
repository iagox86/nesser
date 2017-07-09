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

```ruby
require 'nesser'

s = UDPSocket.new()
result = Nesser::Nesser.query(s: s, hostname: 'google.com', type: Nesser::TYPE_ANY)
puts result
```

You can find all constant definitions in
[the constants.rb file](lib/nesser/packets/constants.rb)

The return from Nesser.query() is an instance of
[Nesser::Answer](lib/nesser/packets/answer.rb).

### Server

Writing a server is a little more complicated, because you have to deal with
much more of the nitty gritty DNS stuff.

To start a server, create an instance of Nesser, and pass in a block that
handles queries. From [examples/server.rb](lib/nesser/examples/server.rb):

```ruby
nesser = Nesser::Nesser.new(s: s) do |transaction|
  puts transaction

  # ...
end
nesser.wait()
```

This is called once per packet received - since many servers send the same
request several times, that has to be handled by the application. Since the
function starts a thread and returns instantly, `nesser.wait()` is necessary
so the program doesn't end until the thread does.

The transaction is an instance of [Nesser::Transaction](lib/nesser/transaction.rb).
Any methods of transaction that end with an exclamation mark
(`transaction.answer!()`, for example) will send a response and can only be
called once, after which the transaction is done and shouldn't be used anymore.

The request packet can be accessed via `transaction.request`, and the response
can be directly accessed (or changed, though I don't recommend that) via
`transaction.response` and `transaction.response=()`. Both are instances of
[Nesser::Packet](lib/nesser/packets/packet.rb). The response already has the
appropriate `trn_id` and `flags` and the `question`, so all you have to do is
add answers and send it off using `transaction.reply!()`.

A much easier way to reply to a request is to use one of the two helper
functions, `transaction.answer!()` or `transaction.error!()`. Each of these
will take the `transaction.response` packet, with whatever changes have been
made to it, add to it, and send it off.

`transaction.answer!()` takes an optional array of
[Nesser::Answer](lib/nesser/packets/answer.rb), adds them to the packet, then sends
it.

`transaction.error!()` takes a response code (see
[constants.rb](lib/nesser/packets/constants.rb) for the list), updates the
packet with that code, then sends it.

You'll rarely need to do anything with the transaction other than inspecting the
request and using one of those two functions to answer.

Here's a full example that replies to requests for test.com with '1.2.3.4' and
sends a "name not found" error for anything else:

```ruby
require 'socket'
require 'nesser'

s = UDPSocket.new()

nesser = Nesser::Nesser.new(s: s) do |transaction|
  if transaction.request.questions[0].name == 'test.com'
    transaction.answer!([Nesser::Answer.new(
      name: 'test.com',
      type: Nesser::TYPE_A,
      cls: Nesser::CLS_IN,
      ttl: 1337,
      rr: Nesser::A.new(address: '1.2.3.4')
    )])
  else
    transaction.error!(Nesser::RCODE_NAME_ERROR)
  end
  puts(transaction)
end
nesser.wait()
```

We currently support A, NS, CNAME, SOA, MX, TXT, and AAAA records. We can also
parse and send unknown types as well. You can find the definitions in
[rr_types.rb](lib/nesser/packets/rr_types.rb).

For quick reference:

* `a = Nesser::A.new(address: '1.2.3.4')`
* `ns = Nesser::NS.new(name: 'google.com')`
* `cname = Nesser::CNAME.new(name: 'google.com')`
* `soa = Nesser::SOA.new(primary: 'google.com', responsible: 'test.google.com', serial: 1, refresh: 2, retry_interval: 3, expire: 4, ttl: 5)`
* `mx = Nesser::MX.new(name: 'mail.google.com', preference: 10)`
* `txt = Nesser::TXT.new(data: 'hello this is data!')`
* `aaaa = Nesser::AAAA.new(address: '::1')`
* `unknown = Nesser::RRUnknown.new(type: 0x1337, data: 'datagoeshere')`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iagox86/nesser

Please try to follow my style as much as possible, and update test coverage
when necessary!

## Version history / changelog

* 0.0.1 - Test deploy
* 0.0.2 - Code complete
* 0.0.3 - First actual release
