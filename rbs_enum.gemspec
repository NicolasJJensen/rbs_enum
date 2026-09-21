# frozen_string_literal: true

require_relative "lib/rbs_enum/version"

Gem::Specification.new do |spec|
  spec.name = "rbs_enum"
  spec.version = RbsEnum::VERSION
  spec.authors = ["Nicolas J Jensen"]
  spec.email = ["nicolasjensen9@gmail.com"]

  spec.summary = "Read enum-like unions from RBS aliases"
  spec.description = <<~DESC
    RbsEnum reads the allowed values out of an RBS type alias so Ruby code can use the
    same list the signature already declares, instead of repeating it in a constant.
    It scans the .rbs files under a signature root with a regular expression and returns
    flat unions of symbol or string literals. It does not depend on the rbs gem and does
    not build a type model, so anything more involved than a literal union is ignored.
  DESC
  spec.homepage = "https://github.com/NicolasJJensen/rbs_enum"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "README.md", "CHANGELOG.md", "LICENSE.txt"]
      .select { |f| File.file?(f) }
  end
  spec.require_paths = ["lib"]
end
