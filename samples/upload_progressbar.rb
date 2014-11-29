#
# Sample upload code that shows a progressbar
# using the library 'ruby-progressbar'
#
# Usage:
#   ruby upload_progressbar.rb http://server file_to_upload
#

url  = ARGV[0]
path = ARGV[1]

require 'ruby-uploader'
require 'logger'
require 'ruby-progressbar'

class BeforeChunk
  def initialize(holder)
    @holder = holder
  end

  def execute(_, count, total_count, _)
    return unless count == 0
    @holder[:progressbar] = ProgressBar.create(starting_at: 0, total: total_count + 1)
  end
end

class AfterChunk
  def initialize(holder)
    @holder = holder
  end

  def execute(_, _, _, _)
    @holder[:progressbar].increment
  end
end

Uploader::Upload.new(URI(url), path) do
  holder = {}
  add_handler :before_chunk, BeforeChunk.new(holder)
  add_handler :after_chunk, AfterChunk.new(holder)
  execute
end
