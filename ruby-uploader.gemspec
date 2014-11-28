lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby-uploader/version'

Gem::Specification.new do |gem|
  gem.name          = 'ruby-uploader'
  gem.version       = Uploader::VERSION
  gem.authors       = ['Guillaume Giamarchi']
  gem.email         = ['guillaume.giamarchi@gmail.com']
  gem.licenses      = ['MIT']
  gem.description   = 'Ruby HTTP chunked uploader with transfert progress'
  gem.summary       = 'Ruby HTTP chunked uploader with transfert progress'
  gem.homepage      = 'https://github.com/ggiamarchi/ruby-uploader'
  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.require_paths = ['lib']
end
