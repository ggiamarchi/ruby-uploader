require 'net/http'
require 'uri'

module Uploader
  class Upload

    def initialize(uri, headers, path)
      @uri      = uri
      @headers  = headers
      @path     = path
      @response = nil
    end

    def execute
      Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == 'https') do |http|

        headers = @headers ? default_headers.merge(@headers) : default_headers

        request = Put.new(@uri, headers).tap do |r|
          r.body_stream = File.open(@path)
        end

        @response = http.request(request)
        @response
      end
    end

    private

    def default_headers
      {
        'Content-Type'      => 'application/octet-stream',
        'Content-Length'    => File.stat(@path).size.to_s,
        'Transfer-Encoding' => 'chunked'
      }
    end

    class Put < Net::HTTP::Put

      def initialize(path, headers)
        super path, headers
      end

      private

      def send_request_with_body_stream(sock, ver, path, f)
        write_header sock, ver, path
        wait_for_continue sock, ver if sock.continue_timeout
        chunker = Chunker.new(sock, self['Content-Length'])
        IO.copy_stream(f, chunker)
        chunker.finish
      end

      class Chunker
        def initialize(sock, content_length)
          @sock = sock
          @prev = nil
          @count = 0
          @total_count = nil
          @content_length = content_length.to_i
        end

        def write(buf)
          @total_count = @content_length / buf.bytesize.to_i if @total_count.nil?

          puts "#{@count} / #{@total_count}"

          @sock.write("#{buf.bytesize.to_s(16)}\r\n")
          rv = @sock.write(buf)
          @sock.write("\r\n")
          @count += 1
          rv
        end

        def finish
          @sock.write("0\r\n\r\n")
        end
      end
    end
  end
end
