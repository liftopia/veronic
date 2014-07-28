Gem::Specification.new do |s|
  s.name        = 'veronic'
  s.version     = '0.0.31'
  s.date        = '2014-07-28'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.summary     = "Veronic, a simple cloud deployer"
  s.description = "A simple cloud deployer"
  s.authors     = ["Liftopia"]
  s.email       = 'ops@liftopia.com'
  s.files       = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.homepage    = 'http://github.com/liftopia/veronic'
  s.license     = 'MIT'
  s.add_dependency('chef')
  s.add_dependency('knife-ec2')
  s.add_dependency('aws-sdk')
  s.add_dependency('route53')
  s.add_dependency('nokogiri', '~> 1.5.11')
end
