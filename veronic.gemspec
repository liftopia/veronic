Gem::Specification.new do |s|
  s.name        = 'veronic'
  s.version     = '0.0.12'
  s.date        = '2013-04-05'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.summary     = "Veronic, deux qui la tiennent trois qui la niquent"
  s.description = "A simple cloud deployer"
  s.authors     = ["Gabriel Klein"]
  s.email       = 'gabriel.klein.fr@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
  s.homepage    = 'http://github.com/GabKlein/veronic'
  s.add_dependency('chef')
  s.add_dependency('knife-ec2')
  s.add_dependency('aws-sdk')
  s.add_dependency('route53')
end
