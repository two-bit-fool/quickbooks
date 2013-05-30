Gem::Specification.new do |s|
  s.name = 'quickbooks'
  s.version = "0.5.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.5") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Parker", "Matt Smith"]
  s.date = %q{2010-02-22}

  s.summary = "A Ruby implementation of the QuickBooks SDK (QBXML) and the QuickBooks Merchant Services SDK (QBMSXML)."
  s.description = "Read and Write QuickBooks data through the QuickBooks API using WIN32OLE and QBXML. Other connection types to come."

  s.email = ["gems@behindlogic.com", "matthewgarysmith+quickbooksgem@gmail.com"]
  s.extra_rdoc_files = ["History.txt", "LICENSE", "README.textile"]
  s.files = [
    "History.txt",
    "LICENSE",
    "README.textile",
  ] + Dir['lib/**/*.rb'] + Dir['spec/**/*']
  s.has_rdoc = true
  s.homepage = %q{http://github.com/two-bit-fool/quickbooks}
  s.rdoc_options = ["--main", "README.textile"]
  s.require_paths = ["lib"]
  s.rubyforge_project = 'quickbooks'
  s.rubygems_version = %q{1.3.5}
  s.test_files = Dir['spec/**/*.rb']
end