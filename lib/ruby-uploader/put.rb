require 'net/http'
require 'uri'

module Uploader
  class Put < Net::HTTP::Put
    def initialize(path, headers, handlers)
      @handlers = handlers
      super path, headers
    end

    private

    def send_request_with_body_stream(sock, ver, path, f)
      write_header sock, ver, path
      wait_for_continue sock, ver if sock.continue_timeout
      chunker = Chunker.new(sock, self['Content-Length'], @handlers)
      IO.copy_stream(f, chunker)
      chunker.finish
    end
  end

  class Chunker
    def initialize(sock, content_length, handlers)
      @sock = sock
      @prev = nil
      @count = 0
      @total_count = nil
      @content_length = content_length.to_i
      @handlers = handlers
    end

    def write(buf)
      @total_count = @content_length / buf.bytesize.to_i if @total_count.nil?

      @handlers[:before_chunk].each do |handler|
        handler.execute buf, @count, @total_count, @content_length
      end

      @sock.write("#{buf.bytesize.to_s(16)}\r\n")
      rv = @sock.write(buf)
      @sock.write("\r\n")

      @handlers[:after_chunk].each do |handler|
        handler.execute buf, @count, @total_count, @content_length
      end

      @count += 1

      rv
    end

    def finish
      @sock.write("0\r\n\r\n")
    end
  end
end
