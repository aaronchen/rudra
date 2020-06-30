# rudra

Rudra: A Selenium IDE alternative using Ruby binding of selenium-webdriver.

# Install

`gem install rudra`

# How To Use

```ruby
require 'rudra'

# Initailize using Chrome and zh-TW locale
rudra = Rudra.new browser: :chrome, locale: :zh_tw

# Initialize headless with 1920x1080 window size
rudra = Rudra.new headless: true, window_size: '1920,1080'

# Sample Steps
rudra.puts 'Search: webdriver'
rudra.open 'https://www.google.com'
rudra.puts 'Go to Google Search'
rudra.send_keys 'name=q', 'webdriver', :enter
rudra.puts 'Wait until page title contains: webdriver'
rudra.wait_for_title 'webdriver'
rudra.puts 'Scroll to footer'
rudra.scroll_into_view '#fbar'
rudra.puts 'Draw a redmark'
rudra.draw_redmark '#fsl'
rudra.puts 'Save a screenshot'
rudra.save_screenshot 'sample_screen'
rudra.puts 'Clear the drawing'
rudra.clear_drawings
rudra.puts 'Quit the driver'
rudra.quit

#
# Rudra supports Basic/Digest Authentication using a built-in Chrome extension
#
require 'rudra'

rudra = Rudra.new auth_username: 'guest', auth_password: 'guest'
rudra.puts 'Basic/Digest Authentication Test'
rudra.open 'https://jigsaw.w3.org/HTTP/Basic/' # Basic Authentication test
# rudra.open 'https://jigsaw.w3.org/HTTP/Digest/' # Digest Authentication test
rudra.save_screenshot 'Authentication Pass'
rudra.quit
```

# Supported **_locator_**

**_Format: 'how=what'_**

- `css=.btn`
- `class=btn-primary`
- `id=frame1`
- `name=j_username`
- `xpath=//span/a`
- etc

If **_how_** is not specified, locator starting with `/` or `(` will be parsed as **xpath**, while `.`, `[` and `#` are treated as **css**.

**css** pseudo selector support => `:eq()`

# Documentation

- [Rudra Documentation](https://aaronchen.github.io/rudra/Rudra.html)
- [Ruby selenium-webdriver](https://www.rubydoc.info/gems/selenium-webdriver)
- [Selenium::WebDriver::ActionBuilder](https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver/ActionBuilder)
- [Selenium::WebDriver::Keys](https://www.rubydoc.info/gems/selenium-webdriver/Selenium/WebDriver/Keys)
