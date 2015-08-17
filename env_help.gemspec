# encoding: utf-8
Gem::Specification.new do |s|
  s.name          = 'env_help'
  s.version       = '0.4.7'
  s.date          = '2015-08-11'
  s.summary       = 'Env Help'
  s.description   = 'Unstructured inconsistent domain specific operation-queue conventions for parsing hashes with string values'
  s.authors       = ['Alexei']
  s.email         = ''
  s.files         = Dir["lib/**/*.*"]
  s.homepage      = 'https://github.com/alexeiemam/env-help'
  s.license       = ["MIT"]
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]


  s.add_development_dependency "bundler"
  s.add_development_dependency "coveralls"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"
  s.add_development_dependency "rubocop"
end
