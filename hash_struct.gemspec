require_relative "lib/hash_struct/version"

Gem::Specification.new do |spec|
  spec.name          = "hash_struct"
  spec.version       = HashStruct::VERSION
  spec.authors       = ["Elliot Winkler"]
  spec.email         = ["elliot.winkler@gmail.com"]

  spec.summary       = "Give your hashes some structure."
  spec.description   = "hash_struct provides a object-oriented interface over your hash and allows you to tighten the data inside it using a schema."
  spec.homepage      = "https://github.com/mcmire/hash_struct"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mcmire/hash_struct"
  spec.metadata["changelog_uri"] = "https://github.com/mcmire/hash_struct/tree/master/CHANGELOG.md"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 5.0", "< 7.0"
end
