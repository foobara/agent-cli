require_relative "version"

Gem::Specification.new do |spec|
  spec.name = "foobara-agent-cli"
  spec.version = Foobara::AgentCli::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Enables a Foobara::Agent to be ran as a CLI tool"
  spec.homepage = "https://github.com/foobara/agent-cli"
  spec.license = "MPL-2.0"
  spec.required_ruby_version = Foobara::AgentCli::MINIMUM_RUBY_VERSION

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "src/**/*",
    "LICENSE*.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.add_dependency "foobara-agent", "~> 0.0.1"

  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
