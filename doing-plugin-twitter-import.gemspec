Gem::Specification.new do |s|
  s.name        = "doing-plugin-twitter-import"
  s.version     = "0.0.3"
  s.summary     = "Twitter timeline import for Doing"
  s.description = "Imports entries from the Twitter timeline to Doing"
  s.authors     = ["Brett Terpstra"]
  s.email       = "me@brettterpstra.com"
  s.files       = ["lib/doing-plugin-twitter-import.rb"]
  s.homepage    = "https://brettterpstra.com"
  s.license     = "MIT"
  s.add_runtime_dependency('twitter', '~> 7.0')
end
