
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "task/tree/version"

Gem::Specification.new do |spec|
  spec.name          = "task-tree"
  spec.version       = Task::Tree::VERSION
  spec.authors       = ["Ewoudt Kellerman"]
  spec.email         = ["ewoudt.kellerman@gmail.com"]

  spec.summary       = %q{Task Tree is a CLI tool that helps you keep track of your tasks in a tree structure}
  spec.homepage      = "https://github.com/hellola/task-tree"
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "http://mygemserver.com"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency "bundler", "~> 1.16"
  spec.add_dependency "rake", "~> 10.0"
  spec.add_dependency "tty"
  spec.add_dependency "tty-screen"
  spec.add_dependency "rubytree"
  spec.add_dependency "commander"
  spec.add_development_dependency "byebug"
end
