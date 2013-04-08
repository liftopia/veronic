Gem::Specification.new do |s|
  s.name        = 'veronic'
  s.version     = '0.0.3'
  s.date        = '2013-04-05'
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.summary     = "veronic, deux qui la tiennent trois qui la niquent"
  s.description = "A simple cloud deployer"
  s.authors     = ["Gabriel Klein"]
  s.email       = 'gabriel@liftopia.com'
  s.files       = `git ls-files`.split("\n")
  s.require_paths = ["lib"]
end