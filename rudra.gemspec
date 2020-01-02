Gem::Specification.new do |spec|
  spec.name          = 'rudra'
  spec.version       = '1.0.9'
  spec.date          = '2020-01-03'
  spec.author        = 'Aaron Chen'
  spec.email         = 'aaron@oobo.be'

  spec.summary       = %(Selenium IDE-like Webdriver)
  spec.description   = %(Selenium IDE alternative using selenium-webdriver)
  spec.homepage      = 'https://www.github.com/aaronchen/rudra'
  spec.files         = ['lib/rudra.rb']
  spec.license       = 'MIT'

  spec.add_development_dependency 'yard', '~> 0.9.22'
  spec.add_dependency 'selenium-webdriver', '~> 3.142', '>= 3.142.7'
  spec.add_dependency 'webdrivers', '~> 4.2', '>= 4.2.0'
end
