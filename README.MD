# PowerBar [![Gem Version](https://badge.fury.io/rb/powerbar.svg)](https://badge.fury.io/rb/powerbar)

This is PowerBar - The last progressbar-library you'll ever need.

## Features

* Detects when stdout is not a terminal and automatically falls back to logging
  * Does not clutter your log-files with ansi-codes!
  * If your CLI-app can run interactively and non-interactively (e.g. cronjob)
    you will automatically get reasonable progress-output in both modes.
  * By default prints to stderr but can call any output-method
    of your choice (e.g. your favorite Logger).

* Fully customizable; all output is template-driven.

* All output is optional. You may set PowerBar to silently collect progress
  information (percentage-done, throughput, ETA, etc.) and then use the
  computed values elsewhere in your app.

* All state can be updated at any time. For example: If you're monitoring a
  multi-part operation then you can change the status-message of a running
  PowerBar to reflect the current state.

## Demo

![screencast](https://github.com/busyloop/powerbar/raw/master/ass/screencast.gif?raw=true)

## Installation

`gem install powerbar`

## Getting Started

Watch the demo that was installed along with the gem:

`powerbar-demo`

Then look at the [source-code](https://github.com/busyloop/powerbar/blob/master/bin/powerbar-demo) of the demo. Pretty much all use-cases are covered in there, including templates and how to hook in your own logger.


## Example (for the impatient)

```
#!/usr/bin/env ruby

require 'powerbar'

total = 100000
step = 1000

p = PowerBar.new

# Override some defaults to demonstrate how the settings work
p.settings.tty.finite.template.barchar = '*'
p.settings.tty.finite.template.padchar = '.'

# Dummy loop to simulate some progress
(0..total).step(step).each do |i|
  p.show(:msg => 'DEMO 1 - Ten seconds of progress', :done => i, :total => total)
  sleep 0.1
end
p.close
```

## Documentation?

Use the [source](https://github.com/busyloop/powerbar/blob/master/lib/powerbar.rb), Luke!

## License (MIT)

Copyright (C) 2011 by moe@busyloop.net
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

