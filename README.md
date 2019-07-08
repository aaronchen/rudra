# rudra

Rudra: A Selenium IDE alternative using Ruby binding of selenium-webdriver.

# Install

`gem install rudra`

# How To Use

```ruby
require 'rudra'

rudra = Rudra.new(browser: :chrome, locale: :zh_tw)

rudra.mkdir('./screenshots')
rudra.open('https://www.google.com')
rudra.send_keys('name=q', 'webdriver', :enter)
rudra.wait_for_title('webdriver')
rudra.click('#nav a.fl:eq(1)')
rudra.scroll_into_view('.fbar')
rudra.draw_redmark('#fsl')
rudra.save_screenshot('./screenshots/sample.png')
rudra.clear_drawings
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

If **_how_** is not specified, locator starting with `//` or `(` will be parsed as **xpath**, while `.`, `[` and `#` are treated as **css**.

**css** pseudo selector support => `:eq()`

# Documentation

- [Rudra Documentation](https://aaronchen.github.io/rudra/Rudra.html)
- [Ruby selenium-webdriver 3.142.3](https://www.rubydoc.info/gems/selenium-webdriver/3.142.3/Selenium)
- [Selenium::WebDriver::ActionBuilder](https://www.rubydoc.info/gems/selenium-webdriver/3.142.3/Selenium/WebDriver/ActionBuilder)
- [Selenium::WebDriver::Keys](https://www.rubydoc.info/gems/selenium-webdriver/3.142.3/Selenium/WebDriver/Keys)
