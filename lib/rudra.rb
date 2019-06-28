require 'selenium-webdriver'
require 'webdrivers/chromedriver'
require 'webdrivers/geckodriver'

Webdrivers.install_dir = './webdrivers/'
# Selenium::WebDriver::Chrome::Service.driver_path = './webdrivers/chromedriver'
# Selenium::WebDriver::Firefox::Service.driver_path = './webdrivers/geckodriver'

# Selenium IDE-like WebDriver based upon Ruby binding
# @author Aaron Chen
# @attr_reader [Symbol] browser The chosen browser
# @attr_reader [WebDriver::Driver] driver The driver instance
#   of the chosen browser
# @attr_reader [String] locale The browser locale
# @attr_reader [Integer] timeout The driver timeout
class Rudra
  # Supported Browsers
  BROWSERS = %i[chrome firefox safari].freeze

  # Element Finder Methods
  HOWS = %i[
    class class_name css id link link_text
    name partial_link_text tag_name xpath
  ].freeze

  attr_reader :browser, :driver, :locale, :timeout

  # Initialize an instance of Rudra
  # @param [Hash] options the options to initialize Rudra
  # @option options [Symbol] :browser (:chrome) the supported
  #   browsers: :chrome, :firefox, :safari
  # @option options [String] :locale ('en') the browser locale
  # @option options [Integer] :timeout (30) implicit_wait timeout
  def initialize(options = {})
    self.browser = options.fetch(:browser, :chrome)
    self.locale = options.fetch(:locale, 'en')

    initialize_driver

    self.timeout = options.fetch(:timeout, 30)
  end

  #
  # Driver Functions
  #

  # Get the active element
  # @return [WebDriver::Element] the active element
  def active_element
    driver.switch_to.active_element
  end

  # Add a cookie to the browser
  # @param [Hash] opts the options to create a cookie with
  # @option opts [String] :name a name
  # @option opts [String] :value a value
  # @option opts [String] :path ('/') a path
  # @option opts [Boolean] :secure (false) a boolean
  # @option opts [Time, DateTime, Numeric, nil] :expires (nil) expiry date
  def add_cookie(opts = {})
    driver.manage.add_cookie(opts)
  end

  # Accept an alert
  def alert_accept
    switch_to_alert.accept
  end

  # Dismiss an alert
  def alert_dismiss
    switch_to_alert.dismiss
  end

  # Send keys to an alert
  def alert_send_keys(keys)
    switch_to_alert.send_keys(keys)
  end

  # Move back a single entry in the browser's history
  def back
    driver.navigate.back
  end

  # Open a blank page
  def blank
    open('about:blank')
  end

  # Close the current window, or the browser if no windows are left
  def close
    driver.close
  end

  # Get the cookie with the given name
  # @param [String] name the name of the cookie
  # @return [Hash, nil] the cookie, or nil if it wasn't found
  def cookie_named(name)
    driver.manage.cookie_named(name)
  end

  # Get the URL of the current page
  # @return (String) the URL of the current page
  def current_url
    driver.current_url
  end

  # Delete all cookies
  def delete_all_cookies
    driver.manage.delete_all_cookies
  end

  # Delete the cookie with the given name
  # @param [String] name the name of the cookie
  def delete_cookie(name)
    driver.manage.delete_cookie(name)
  end

  # Execute the given JavaScript
  # @param [String] script JavaScript source to execute
  # @param [WebDriver::Element, Integer, Float, Boolean, NilClass, String,
  #   Array] args arguments will be available in the given script in the
  #   'arguments' pseudo-array
  # @return [WebDriver::Element, Integer, Float, Boolean, NilClass, String,
  #   Array] the value returned from the script
  def execute_script(script, *args)
    driver.execute_script(script, *args)
  end

  # Find the first element matching the given locator
  # @param [String] locator the locator to identify the element
  # @return [WebDriver::Element] the element found
  def find_element(locator)
    element = nil
    how, what = parse_locator(locator)

    if how == :css
      new_what, nth = what.scan(/(.*):eq\((\d+)\)/).flatten
      element = find_elements("#{how}=#{new_what}")[nth.to_i] if nth
    end

    element ||= driver.find_element(how, what)

    abort("Failed to find element: #{locator}") unless element

    wait_for { element.displayed? }

    element
  end

  # Find all elements matching the given locator
  # @param [String] locator the locator to identify the elements
  # @return [Array<WebDriver::Element>] the elements found
  def find_elements(locator)
    how, what = parse_locator(locator)
    driver.find_elements(how, what) ||
      abort("Failed to find elements: #{locator}")
  end

  # Move forward a single entry in the browser's history
  def forward
    driver.navigate.forward
  end

  # Make the current window full screen
  def full_screen
    driver.manage.window.full_screen
  end

  # Quit the browser
  def quit
    driver.quit
  end

  # Maximize the current window
  def maximize
    driver.manage.window.maximize
  end

  # Maximize the current window to the size of the screen
  def maximize_to_screen
    size = execute_script(%(
      return { width: window.screen.width, height: window.screen.height };
    ))

    move_window_to(0, 0)
    resize_window_to(size['width'], size['height'])
  end

  # Minimize the current window
  def minimize
    driver.manage.window.minimize
  end

  # Move the current window to the given position
  # @param [Integer] point_x the x coordinate
  # @param [Integer] point_y the y coordinate
  def move_window_to(point_x, point_y)
    driver.manage.window.move_to(point_x, point_y)
  end

  # Open a new tab
  # @return [String] the id of the new tab obtained from #window_handles
  def new_tab
    execute_script('window.open();')
    window_handles.last
  end

  # Open a new window
  # @param [String] name the name of the window
  def new_window(name)
    execute_script(%(
      var w = Math.max(
        document.documentElement.clientWidth, window.innerWidth || 0
      );
      var h = Math.max(
        document.documentElement.clientHeight, window.innerHeight || 0
      );
      window.open("about:blank", arguments[0], `width=${w},height=${h}`);
    ), name)
  end

  # Open the specified URL in the browser
  # @param [String] url the URL of the page to open
  def open(url)
    driver.get(url)
  end

  # Refresh the current page
  def refresh
    driver.navigate.refresh
  end

  # Resize the current window to the given dimension
  # @param [Integer] width the width of the window
  # @param [Integer] height the height of the window
  def resize_window_to(width, height)
    driver.manage.window.resize_to(width, height)
  end

  # Save a PNG screenshot to the given path
  # @param [String] png_path the path of PNG screenshot
  def save_screenshot(png_path)
    driver.save_screenshot(
      png_path.end_with?('.png') ? png_path : "#{png_path}.png"
    )
  end

  # Switch to the currently active modal dialog
  def switch_to_alert
    driver.switch_to.alert
  end

  # Select either the first frame on the page,
  # or the main document when a page contains iframes
  def switch_to_default_content
    driver.switch_to.default_content
  end

  # Switch to the frame with the given id
  def switch_to_frame(id)
    driver.switch_to.frame(id)
  end

  # Switch to the parent frame
  def switch_to_parent_frame
    driver.switch_to.parent_frame
  end

  # Switch to the given window handle
  # @param [String] id the window handle obtained through #window_handles
  def switch_to_window(id)
    driver.switch_to.window(id)
  end

  # Get the title of the current page
  # @return [String] the title of the current page
  def title
    driver.title
  end

  # Wait until the given block returns a true value
  # @param [Integer] seconds seconds before timed out
  # @return [Object] the result of the block
  def wait_for(seconds = timeout)
    Selenium::WebDriver::Wait.new(timeout: seconds).until { yield }
  end

  # Wait until the title of the page including the given string
  # @param [String] string the string to compare
  def wait_for_title(string)
    wait_for { title.downcase.include?(string.downcase) }
  end

  # Wait until the URL of the page including the given url
  # @param [String] url the URL to compare
  def wait_for_url(url)
    wait_for { current_url.include?(url) }
  end

  # Wait until the element, identified by locator, is visible
  # @param [String] locator the locator to identify the element
  def wait_for_visible(locator)
    wait_for { find_element(locator).displayed? }
  end

  # Get the current window handle
  # @return [String] the id of the current window handle
  def window_handle
    driver.window_handle
  end

  # Get the window handles of open browser windows
  # @return [Array<String>] the ids of window handles
  def window_handles
    driver.window_handles
  end

  # Zoom the current page
  # @param [Float] scale the scale of zoom
  def zoom(scale)
    execute_script(%(document.body.style.zoom = arguments[0];), scale)
  end

  #
  # Element Functions
  #

  # Get the value of the given attribute of the element,
  # identified by locator
  # @param [String] locator the locator to identify the element
  # @param [String] attribute the name of the attribute
  # @return [String, nil] attribute value
  def attribute(locator, attribute)
    find_element(locator).property(attribute)
  end

  # If the element, identified by locator, has the given attribute
  # @param [String] locator the locator to identify the element
  # @param [String] attribute the name of the attribute
  # @return [Boolean] the result of the existence of the given attribute
  def attribute?(locator, attribute)
    execute_script(%(
      return arguments[0].hasAttribute(arguments[1]);
    ), find_element(locator), attribute)
  end

  # Blur the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def blur(locator)
    execute_script(
      'var element = arguments[0]; element.blur();',
      find_element(locator)
    )
  end

  # Clear the input of the given element, identified by locator
  # @param [String] locator the locator to identify the element
  def clear(locator)
    find_element(locator).clear
  end

  # Click the given element, identified by locator
  # @param [String] locator the locator to identify the element
  def click(locator)
    find_element(locator).click
  end

  # If the given element, identified by locator, is displayed
  # @param [String] locator the locator to identify the element
  # @return [Boolean]
  def displayed?(locator)
    find_element(locator).displayed?
  end

  # If the given element, identified by locator, is enabled
  # @param [String] locator the locator to identify the element
  # @return [Boolean]
  def enabled?(locator)
    find_element(locator).enabled?
  end

  # Focus the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def focus(locator)
    execute_script(
      'var element = arguments[0]; element.focus();',
      find_element(locator)
    )
  end

  # Hide the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def hide(locator)
    execute_script(%(
      arguments[0].style.display = 'none';
    ), find_element(locator))
  end

  # Hightlight the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def highlight(locator)
    execute_script(%(
      arguments[0].style.backgroundColor = '#FFFF33';
    ), find_element(locator))
  end

  # Click the given element, identified by locator, via Javascript
  # @param [String] locator the locator to identify the element
  def js_click(locator)
    execute_script('arguments[0].click();', find_element(locator))
  end

  # Get the location of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @return [WebDriver::Point] the point of the given element
  def location(locator)
    find_element(locator).location
  end

  # Get the dimensions and coordinates of the given element,
  # identfied by locator
  # @param [String] locator the locator to identify the element
  # @return [WebDriver::Rectangle] the retangle of the given element
  def rect(locator)
    find_element(locator).rect
  end

  # Remove the given attribute from the given element,
  # identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String] attribute the name of the attribute
  def remove_attribute(locator, attribute)
    execute_script(%(
      var element = arguments[0];
      var attributeName = arguments[1];
      if (element.hasAttribute(attributeName)) {
        element.removeAttribute(attributeName);
      }
    ), find_element(locator), attribute)
  end

  # Scroll the given element, identfied by locator, into view
  # @param [String] locator the locator to identify the element
  # @param [Boolean] align_to true if aligned on top or
  #   false if aligned at the bottom
  def scroll_into_view(locator, align_to = true)
    execute_script(
      'arguments[0].scrollIntoView(arguments[1]);',
      find_element(locator),
      align_to
    )
  end

  # Select the given option, identified by locator
  # @param [String] option_locator the option locator to identify the element
  def select(option_locator)
    find_element(option_locator).click
  end

  # If the given element, identified by locator, is selected
  # @param [String] locator the locator to identify the element
  # @return [Boolean]
  def selected?(locator)
    find_element(locator).selected?
  end

  # Send keystrokes to the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String, Symbol, Array] args keystrokes to send
  def send_keys(locator, *args)
    find_element(locator).send_keys(*args)
  end

  # Set the attribute's value of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String] attribute the name of the attribute
  # @param [String] value the value of the attribute
  def set_attribute(locator, attribute, value)
    executeScript(%(
      var element = arguments[0];
      var attribute = arguments[1];
      var value = arguments[2];
      element.setAttribute(attribute, value);
    ), find_element(locator), attribute, value)
  end

  # Show the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def show(locator)
    execute_script(%(
      arguments[0].style.display = '';
    ), find_element(locator))
  end

  # Get the size of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @return [WebDriver::Dimension]
  def size(locator)
    find_element(locator).size
  end

  # Submit the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  def submit(locator)
    find_element(locator).submit
  end

  # Get the tag name of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @return [String] the tag name of the given element
  def tag_name(locator)
    find_element(locator).tag_name
  end

  # Get the text content of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @return [String] the text content of the given element
  def text(locator)
    find_element(locator).text
  end

  # Trigger the given event on the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String] event the event name
  def trigger(locator, event)
    execute_script(%(
      var element = arguments[0];
      var eventName = arguments[1];
      var event = new Event(eventName, {"bubbles": false, "cancelable": false});
      element.dispatchEvent(event);
    ), find_element(locator), event)
  end

  #
  # Tool Functions
  #

  # Clear all drawing
  def clear_drawings
    execute_script(%(
      var elements = window.document.body.querySelectorAll('[id*="rudra_"]');
      for (var i = 0; i < elements.length; i++) {
        elements[i].remove();
      }
      window.rudraTooltipSymbol = 9311;
      window.rudraTooltipLastPos = { x: 0, y: 0 };
    ))
  end

  # Draw an arrow from an element to an element2
  # @param [String] from_locator the locator where the arrow starts
  # @param [String] to_locator the locator where the arrow ends
  # @return [WebDriver::Element] the arrow element
  def draw_arrow(from_locator, to_locator)
    id = random_id

    execute_script(%(
      var element1 = arguments[0];
      var element2 = arguments[1];
      var rect1 = element1.getBoundingClientRect();
      var rect2 = element2.getBoundingClientRect();
      var from = {y: rect1.top};
      var to = {y: rect2.top};
      if (rect1.left > rect2.left) {
        from.x = rect1.left; to.x = rect2.right;
      } else if (rect1.left < rect2.left) {
        from.x = rect1.right; to.x = rect2.left;
      } else {
        from.x = rect1.left; to.x = rect2.left;
      }
      // create canvas
      var canvas = document.createElement('canvas');
      canvas.id = "#{id}";
      canvas.style.left = "0px";
      canvas.style.top = "0px";
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      canvas.style.zIndex = '100000';
      canvas.style.position = "absolute";
      document.body.appendChild(canvas);
      var headlen = 10;
      var angle = Math.atan2(to.y - from.y, to.x - from.x);
      var ctx = canvas.getContext("2d");
      // line
      ctx.beginPath();
      ctx.moveTo(from.x, from.y);
      ctx.lineTo(to.x, to.y);
      ctx.lineWidth  = 3;
      ctx.strokeStyle = '#ff0000';
      ctx.stroke();
      // arrow
      ctx.beginPath();
      ctx.moveTo(to.x, to.y);
      ctx.lineTo(
        to.x - headlen * Math.cos(angle - Math.PI/7),
        to.y - headlen * Math.sin(angle - Math.PI/7)
      );
      ctx.lineTo(
        to.x - headlen * Math.cos(angle + Math.PI/7),
        to.y - headlen * Math.sin(angle + Math.PI/7)
      );
      ctx.lineTo(to.x, to.y);
      ctx.lineTo(
        to.x - headlen * Math.cos(angle - Math.PI/7),
        to.y - headlen * Math.sin(angle - Math.PI/7)
      );
      ctx.lineWidth  = 3;
      ctx.strokeStyle = '#ff0000';
      ctx.stroke();
      return;
    ), find_element(from_locator), find_element(to_locator))

    find_element("id=#{id}")
  end

  # Draw color fill on the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String] color CSS style of backgroundColor
  # @return [WebDriver::Element] the color fill element
  def draw_color_fill(locator, color = 'rgba(255,0,0,0.8)')
    rectangle = rect(locator)
    id = random_id

    execute_script(%(
      var colorfill = window.document.createElement('div');
      colorfill.id = '#{id}';
      colorfill.style.backgroundColor = '#{color}';
      colorfill.style.border = 'none';
      colorfill.style.display = 'block';
      colorfill.style.height = #{rectangle.height} + 'px';
      colorfill.style.left = #{rectangle.x} + 'px';
      colorfill.style.margin = '0px';
      colorfill.style.padding = '0px';
      colorfill.style.position = 'absolute';
      colorfill.style.top = #{rectangle.y} + 'px';
      colorfill.style.width = #{rectangle.width} + 'px';
      colorfill.style.zIndex = '99999';
      window.document.body.appendChild(colorfill);
      return;
    ))

    find_element("id=#{id}")
  end

  # Draw tooltip of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [Hash] options the options to create a tooltip
  # @option options [String] :attribute (title) attribute to draw
  #   the flyover with
  # @option options [Integer] :offset_x (5) offset on x coordinate
  # @option options [Integer] :offset_y (15) offset on y coordinate
  # @option options [Boolean] :from_last_pos (false) if to draw
  #   from last position
  # @option options [Boolean] :draw_symbol (false) if to draw symbol
  # @return [WebDriver::Element] the tooltip element
  def draw_flyover(locator, options = {})
    attribute_name = options.fetch(:attribute, 'title')
    offset_x = options.fetch(:offset_x, 5)
    offset_y = options.fetch(:offset_y, 15)
    from_last_pos = options.fetch(:from_last_pos, false)
    draw_symbol = options.fetch(:draw_symbol, false)

    symbol_id = random_id
    tooltip_id = random_id

    execute_script(%(
      var element = arguments[0];
      if (! window.rudraTooltipSymbol) {
        window.rudraTooltipSymbol = 9311;
      }
      if (! window.rudraTooltipLastPos) {
        window.rudraTooltipLastPos = { x: 0, y: 0 };
      }
      var rect = element.getBoundingClientRect();
      var title = element.getAttribute("#{attribute_name}") || 'N/A';
      var left = window.scrollX + rect.left;
      var top = window.scrollY + rect.top;
      if (#{draw_symbol}) {
        window.rudraTooltipSymbol++;
        var symbol = document.createElement('div');
        symbol.id = "#{symbol_id}";
        symbol.textContent = String.fromCharCode(rudraTooltipSymbol);
        symbol.style.color = '#f00';
        symbol.style.display = 'block';
        symbol.style.fontSize = '12px';
        symbol.style.left = (left - 12) + 'px';
        symbol.style.position = 'absolute';
        symbol.style.top = top + 'px';
        symbol.style.zIndex = '99999';
        document.body.appendChild(symbol);
      }
      var tooltip = document.createElement('div');
      tooltip.id = "#{tooltip_id}";
      tooltip.textContent = (#{draw_symbol}) ?
        String.fromCharCode(rudraTooltipSymbol) + " " + title : title;
      tooltip.style.position = 'absolute';
      tooltip.style.color = '#000';
      tooltip.style.backgroundColor = '#F5FCDE';
      tooltip.style.border = '3px solid #f00';
      tooltip.style.fontSize = '12px';
      tooltip.style.zIndex = '99999';
      tooltip.style.display = 'block';
      tooltip.style.height = '16px';
      tooltip.style.padding = '2px';
      tooltip.style.verticalAlign = 'middle';
      tooltip.style.top = ((#{from_last_pos}) ?
        window.rudraTooltipLastPos.y : (top + #{offset_y})) + 'px';
      tooltip.style.left = ((#{from_last_pos}) ?
        window.rudraTooltipLastPos.x : (left + #{offset_x})) + 'px';
      document.body.appendChild(tooltip);
      if (tooltip.scrollHeight > tooltip.offsetHeight) {
      	tooltip.style.height = (tooltip.scrollHeight + 3) + 'px';
      }
      var lastPos = tooltip.getBoundingClientRect();
      window.rudraTooltipLastPos = {
        x: window.scrollX + lastPos.left, y: window.scrollY + lastPos.bottom
      };
      return;
    ), find_element(locator))

    find_element("id=#{tooltip_id}")
  end

  # Draw redmark around the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [Hash] padding the padding of the given redmark
  # @option padding [Integer] :top (5) top padding
  # @option padding [Integer] :right (5) right padding
  # @option padding [Integer] :bottom (5) bottom padding
  # @option padding [Integer] :left (5) left padding
  # @return [WebDriver::Element] the redmark element
  def draw_redmark(locator, padding = {})
    top = padding.fetch(:top, 5)
    right = padding.fetch(:right, 5)
    bottom = padding.fetch(:bottom, 5)
    left = padding.fetch(:left, 5)

    rectangle = rect(locator)
    id = random_id

    execute_script(%(
      var redmark = window.document.createElement('div');
      redmark.id = '#{id}';
      redmark.style.border = '3px solid red';
      redmark.style.display = 'block';
      redmark.style.height = (#{rectangle.height} + 8 + #{bottom}) + 'px';
      redmark.style.left = (#{rectangle.x} - 4 - #{left}) + 'px';
      redmark.style.margin = '0px';
      redmark.style.padding = '0px';
      redmark.style.position = 'absolute';
      redmark.style.top = (#{rectangle.y} - 4 - #{top}) + 'px';
      redmark.style.width = (#{rectangle.width} + 8 + #{right}) + 'px';
      redmark.style.zIndex = '99999';
      window.document.body.appendChild(redmark);
      return;
    ))

    find_element("id=#{id}")
  end

  # Draw dropdown menu on the given SELECT element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [Hash] options the options to create the dropdown menu
  # @option options [Integer] :offset_x (0) offset on x coordinate
  # @option options [Integer] :offset_y (0) offset on y coordinate
  # @return [WebDriver::Element] the dropdown menu element
  def draw_select(locator, options = {})
    offset_x = options.fetch(:offset_x, 0)
    offset_y = options.fetch(:offset_y, 0)

    id = random_id

    executeScript(%(
      var element = arguments[0];
      var rect = element.getBoundingClientRect();
      var x = rect.left;
      var y = rect.bottom;
      var width = element.offsetWidth;
      function escape(str) {
      	return str.replace(
          /[\\x26\\x0A<>'"]/g,
          function(r) { return "&#" + r.charCodeAt(0) + ";"; }
        );
      }
      var content = "";
      for (var i = 0; i < element.length; i++) {
      	if (!element.options[i].disabled) {
          content += escape(element.options[i].text) + "<br />";
        }
      }
      var dropdown = document.createElement('div');
      dropdown.id = "#{id}";
      dropdown.innerHTML = content;
      dropdown.style.backgroundColor = '#fff';
      dropdown.style.border = '1px solid #000';
      dropdown.style.color = '#000';
      dropdown.style.display = 'block';
      dropdown.style.fontSize = '12px';
      dropdown.style.height = '1px';
      dropdown.style.padding = '2px';
      dropdown.style.position = 'absolute';
      dropdown.style.width = width + 'px';
      dropdown.style.zIndex = '99999';
      document.body.appendChild(dropdown);
      dropdown.style.height = (dropdown.scrollHeight + 8) + 'px';
      if (dropdown.scrollWidth > width) {
      	dropdown.style.width = (dropdown.scrollWidth + 8) + 'px';
      }
      dropdown.style.left = (x + #{offset_x}) + "px";
      dropdown.style.top = (y + #{offset_y}) + "px";
      return;
    ), find_element(locator))

    find_element("id=#{id}")
  end

  # Draw text on top of the given element, identfied by locator
  # @param [String] locator the locator to identify the element
  # @param [String] text the text to draw
  # @param [Hash] options the options to create the text
  # @option options [String] :color ('#f00') the color of the text
  # @option options [Integer] :font_size (13) the font size of the text
  # @option options [Integer] :top (2) CSS style of top
  # @option options [Integer] :right (20) CSS style of right
  # @return [WebDriver::Element] the text element
  def draw_text(locator, text, options = {})
    color = options.fetch(:color, '#f00')
    font_size = options.fetch(:font_size, 13)
    top = options.fetch(:top, 2)
    right = options.fetch(:right, 20)

    rect = rect(locator)
    id = random_id

    execute_script(%(
      var textbox = window.document.createElement('div');
      textbox.id = '#{id}';
      textbox.innerText = '#{text}';
      textbox.style.border = 'none';
      textbox.style.color = '#{color}';
      textbox.style.display = 'block';
      textbox.style.font = '#{font_size}px Verdana, sans-serif';
      textbox.style.left = #{rect.x} + 'px';
      textbox.style.margin = '0';
      textbox.style.padding = '0';
      textbox.style.position = 'absolute';
      textbox.style.right = #{right} + 'px';
      textbox.style.top = (#{rect.y} + #{rect.height} + #{top}) + 'px';
      textbox.style.zIndex = '99999';
      window.document.body.appendChild(textbox);
      return;
    ))

    find_element("id=#{id}")
  end

  # Create directories, recursively, for the given dir
  # @param [String] dir the directories to create
  def mkdir(dir)
    FileUtils.mkdir_p(dir)
  end

  private

  def browser=(brw)
    unless BROWSERS.include?(brw)
      browsers = BROWSERS.map { |b| ":#{b}" }.join(', ')
      abort("Supported browsers are: #{browsers}")
    end

    @browser = brw
  end

  def locale=(loc)
    @locale = if browser == :firefox
                loc.sub('_', '-').gsub(/(-[a-zA-Z]{2})$/, &:downcase)
              else
                loc.sub('_', '-').gsub(/(-[a-zA-Z]{2})$/, &:upcase)
              end
  end

  def timeout=(seconds)
    driver.manage.timeouts.implicit_wait = seconds
    driver.manage.timeouts.page_load = seconds
    driver.manage.timeouts.script_timeout = seconds
    @timeout = seconds
  end

  def initialize_driver
    @driver = if browser == :chrome
                Selenium::WebDriver.for(:chrome, options: chrome_options)
              elsif browser == :firefox
                Selenium::WebDriver.for(:firefox, options: firefox_options)
              else
                Selenium::WebDriver.for(:safari)
              end
  end

  def chrome_options
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('disable-infobars')
    options.add_argument('disable-notifications')
    options.add_preference('intl.accept_languages', locale)
    options
  end

  def firefox_options
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_preference('intl.accept_languages', locale)
    options
  end

  def parse_locator(locator)
    unmatched, how, what = locator.split(/^([A-Za-z]+)=(.+)/)

    how = if !unmatched.strip.empty?
            what = unmatched
            case unmatched
            when /^[\.#\[]/
              :css
            when %r{^(\/\/|\()}
              :xpath
            end
          else
            how.to_sym
          end

    abort("Cannot parse locator: #{locator}") unless HOWS.include?(how)

    [how, what]
  end

  def random_id(length = 8)
    charset = [(0..9), ('a'..'z')].flat_map(&:to_a)
    id = Array.new(length) { charset.sample }.join
    "rudra_#{id}"
  end
end
