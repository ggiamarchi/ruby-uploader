# Ruby Uploader

[![Build Status](https://api.travis-ci.org/ggiamarchi/ruby-uploader.png?branch=master)](https://travis-ci.org/ggiamarchi/ruby-uploader)

This library provides a simple HTTP uploader based on chunks transfer. It supports handlers,
useful to make custom request configuration and to read the progression of the file transfer.

## Quickstart

First, install `ruby-uploader`

```
gem install ruby-uploader
```

`ruby-uploader` set the necessary headers and configure the request to enable chunk transfer.
Below, the most basic example do not require any configuration

```ruby
require 'ruby-uploader/uploader'

uploader = Uploader::Upload.new(URI('https://server/path/to/upload'), 'myfile.bin')

uploader.execute
```

or with the more user friendly block syntax

```ruby
Uploader::Upload.new(URI('https://server/path/to/upload'), 'myfile.bin') do
  execute
end
```

Optionally, headers can be set using a Hash parameter

```ruby
Uploader::Upload.new(URI('https://server/path/to/upload'), 'myfile.bin', { 'custom-header' => 'value' }) do
  execute
end
```

For more configuration capabilities, see the Handlers section

## Handlers

`ruby-uploader` support handlers at four different steps of the upload request process
* Before the request is fired
* Before each chunk is sent
* After each chunk has been sent
* After the HTTP response is received

Set a handler is done usine the method `add_handler` on the `Upload` object. several handlers
can be add on the uploader, even several of the same type.

### Add a `:before` handler

This handler is triggered before the request is fired. It give access to the request object
which is an instance of type `Net::HTTPRequest` from the `net/http` standard API.

```ruby
class BeforeRequest
  def execute(request)
    ...
  end
end

uploader.add_handler :before, BeforeRequest.new
```

### Add a `:before_chunk` handler

This handler is triggered for each chunk, before it is sent to the server. It give access to the
following information :
* `chunk` - the chunk of data 
* `count` - the number of the chunk (first chunk is `0`)
* `total_count` - total number of chunks to transfer 
* `content_length` - the value of the corresponding HTTP header

```ruby
class BeforeChunk
  def execute(chunk, count, total_count, content_length)
    ...
  end
end

uploader.add_handler :before_chunk, BeforeChunk.new
```

### Add a `:after_chunk` handler

This handler is triggered for each chunk, after it has been sent to the server. Its structure is
identical to the one of the `before_chunk` handler

```ruby
class AfterChunk
  def execute(chunk, count, total_count, content_length)
    ...
  end
end

uploader.add_handler :after_chunk, AfterChunk.new
```

### Add a `:after` handler

This handler is triggered after the response is received for the server. It give access to the
response object which is an instance of type `Net::HTTPResponse` from the `net/http` standard API.

```ruby
class AfterRequest
  def execute(response)
    ...
  end
end

uploader.add_handler :after, AfterRequest.new
```

## Putting all together

An uploader with one handler of each kind that just do log.

```ruby
require 'ruby-uploader/uploader'
require 'logger'

class Handler
  def initialize
    @logger = Logger.new(STDOUT)
  end
end

class BeforeRequest < Handler
  def execute(request)
    @logger.info('start processing request')
  end
end

class AfterResponse < Handler
  def execute(response)
    @logger.info('finished processing request')
  end
end

class BeforeChunk < Handler
  def execute(buf, count, total_count, content_length)
    puts "start processing chunk #{count} of #{total_count}"
  end
end

class AfterChunk < Handler
  def execute(buf, count, total_count, content_length)
    puts "finished processing chunk #{count} of #{total_count}"
  end
end

Uploader::Upload.new(URI('https://server/path/to/upload'), 'myfile.bin') do
  add_handler :before, BeforeRequest.new
  add_handler :after,  AfterResponse.new
  add_handler :before_chunk, BeforeChunk.new
  add_handler :after_chunk, AfterChunk.new
  execute
end
```
