Gem::Specification.new do |spec|
  spec.name          = 'rudra'
  spec.version       = '1.0.7'
  spec.date          = '2019-09-11'
  spec.author        = 'Aaron Chen'
  spec.email         = 'aaron@611b.com'

  spec.summary       = %(Selenium IDE-like Webdriver)
  spec.description   = %(Selenium IDE alternative using selenium-webdriver)
  spec.homepage      = 'https://www.github.com/aaronchen/rudra'
  spec.files         = ['lib/rudra.rb']
  spec.license       = 'MIT'

  spec.add_development_dependency 'yard', '~> 0.9.20'
  spec.add_dependency 'selenium-webdriver', '~> 3.142', '>= 3.142.4'
  spec.add_dependency 'webdrivers', '~> 4.1', '>= 4.1.2'
end
