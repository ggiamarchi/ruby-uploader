require 'ruby-uploader/put'

module Uploader
  class Upload
    def initialize(url, path, headers = nil, &block)
      @url = url
      @headers  = headers
      @path     = path
      @response = nil
      @handlers = {
        before:       [],
        after:        [],
        before_chunk: [],
        after_chunk:  []
      }
      instance_eval(&block) if block_given?
    end

    def execute
      Net::HTTP.start(@url.host, @url.port, use_ssl: @url.scheme == 'https') do |http|

        headers = @headers ? default_headers.merge(@headers) : default_headers

        request = Put.new(@url, headers, @handlers).tap do |r|
          r.body_stream = File.open(@path)
        end

        @handlers[:before].each do |handler|
          handler.execute request
        end

        @response = http.request(request)

        @handlers[:after].each do |handler|
          handler.execute @response
        end

        @response
      end
    end

    def add_handler(phase, handler)
      fail "Handler phase #{phase} does not exists" unless @handlers.key? phase
      @handlers[phase] << handler
    end

    private

    def default_headers
      {
        'Content-Type'      => 'application/octet-stream',
        'Content-Length'    => File.stat(@path).size.to_s,
        'Transfer-Encoding' => 'chunked'
      }
    end
  end
end
