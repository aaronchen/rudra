# rudra

Rudra: A Selenium IDE alternative using Ruby binding of selenium-webdriver.

# Install

`gem install rudra`

# Test Case

```ruby
require 'rudra'

rudra = Rudra.new(browser: :chrome, locale: 'zh_tw')
rudra.mkdir('./screenshots')

rudra.open('https://www.google.com')
rudra.send_keys('name=q', 'webdriver', :enter)
rudra.wait_for_title('webdriver')
udra.save_screenshot('./screenshots/sample.png')
```

# Documentation

[https://aaronchen.github.io/rudra/Rudra.html](https://aaronchen.github.io/rudra/Rudra.html)
