# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gasm/version'

Gem::Specification.new do |spec|
  unless spec.respond_to?(:metadata)
    # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host',
    # or delete this section to allow pushing this gem to any host.
    raise <<-ERR
      RubyGems 2.0 or newer is required to protect against public gem pushes.
    ERR
  end

  spec.name          = 'gasm'
  spec.version       = Gasm::VERSION
  spec.authors       = ['David Siaw']
  spec.email         = ['davidsiaw@gmail.com']

  spec.summary       = 'General ASsembler Maker'
  spec.description   = 'Generates an assembler based on an assembly description'
  spec.homepage      = 'https://github.com/davidsiaw/gasm'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/davidsiaw/gasm'
  spec.metadata['changelog_uri'] = 'https://github.com/davidsiaw/gasm'

  spec.files = Dir['{data,exe,lib,bin}/**/*'] +
               %w[Gemfile gasm.gemspec]
  spec.test_files    = Dir['{spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rspec'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
end
