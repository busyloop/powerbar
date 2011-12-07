#
# Copyright (C) 2011 by moe@busyloop.net
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

require 'powerbar/version'
require 'ansi'
require 'hashie/mash'

class PowerBar
  #
  # This is PowerBar - The last progressbar-library you'll ever need.
  #

  STRIP_ANSI = Regexp.compile '\e\[(\d+)(;\d+)?(;\d+)?[m|K]', nil

  def initialize(opts={})
    @@exit_hooked = false
    @state = Hashie::Mash.new( {
      :time_last_show => Time.at(0),    # <- don't mess with us
      :time_last_update => Time.at(0),  # <- unless you know
      :time_start => nil,               # <- what you're doing!
      :time_now => nil,                 # <- 
      :msg => 'PowerBar!',
      :done => 0,
      :total => :unknown,
      :settings => {
        :rate_sample_max_interval => 10,  # See PowerBar::Rate
        :rate_sample_window => 6,         # See PowerBar::Rate
        :force_mode => nil, # set to :tty or :notty to force either mode
        :tty => {      # <== Settings when stdout is a tty
          :finite => { # <== Settings for a finite progress bar (when total != :unknown)
            # The :output Proc is called to draw on the screen --------------------.
            :output => Proc.new{ |s| $stderr.print s[0..terminal_width()-1] }, # <-'
            :interval => 0.1, # Minimum interval between screen refreshes (in seconds)
            :template => { # <== template for a finite progress bar on a tty
              :pre  => "\e[1000D\e[?25l",  # printed before the progress-bar
              #
              # :main is the progressbar template
              #
              # The following tokens are available:
              #   msg, bar, rate, percent, elapsed, eta, done, total
              #
              # Tokens may be used like so:
              #    ${<foo>}
              # OR:
              #    ${surrounding <foo> text}
              #
              # The surrounding text is only rendered when <foo>
              # evaluates to something other than nil.
              :main => '${<msg>}: ${[<bar>] }${<rate>/s }${<percent>% }${<elapsed>}${, ETA: <eta>}',
              :post => '',             # printed after the progressbar
              :wipe => "\e[1000D\e[K", # printed when 'wipe' is called
              :close => "\e[?25h\n",   # printed when 'close' is called
              :exit => "\e[?25h",      # printed if the process exits unexpectedly
              :barchar => "\u2588",    # fill-char for the progress-bar
              :padchar => "\u2022"     # padding-char for the progress-bar
            },
          },
          :infinite => { # <== Settings for an infinite progress "bar" (when total is :unknown)
            :output => Proc.new{ |s| $stderr.print s[0..terminal_width()-1] },
            :interval => 0.1,
            :template => {
              :pre  => "\e[1000D\e[?25l",
              :main => "${<msg>}: ${<done> }${<rate>/s }${<elapsed>}",
              :post => "\e[K",
              :wipe => "\e[1000D\e[K",
              :close => "\e[?25h\n",
              :exit => "\e[?25h",
              :barchar => "\u2588",
              :padchar => "\u2022"
            },
          }
        },
        :notty => { # <== Settings when stdout is not a tty
          :finite => {
            # You may want to hook in your favorite Logger-Library here. ---.
            :output => Proc.new{ |s| $stderr.print s },  # <----------------'
            :interval => 1,
            :line_width => 78, # Maximum output line width
            :template => {
              :pre  => '',
              :main => "${<msg>}: ${<done>}/${<total>}, ${<percent>%}${, <rate>/s}${, elapsed: <elapsed>}${, ETA: <eta>}\n",
              :post => '',
              :wipe => '',
              :close => nil,
              :exit => nil,
              :barchar => "#",
              :padchar => "."
            },
          },
          :infinite => {
            :output => Proc.new{ |s| $stderr.print s },
            :interval => 1,
            :line_width => 78,
            :template => {
              :pre  => "",
              :main => "${<msg>}: ${<done> }${<rate>/s }${<elapsed>}\n",
              :post => "",
              :wipe => "",
              :close => nil,
              :exit => nil,
              :barchar => "#",
              :padchar => "."
            },
          }
        }
      }
    }.merge(opts) )
  end

  # Access the settings-hash
  def settings
    @state.settings
  end

  # Access settings under current scope (e.g. tty.infinite)
  def scope
    scope_hash = [settings.force_mode,state.total].hash
    return @state.scope unless @state.scope.nil? or scope_hash != @state.scope_hash
    state.scope_at = [
      settings.force_mode || ($stdout.isatty ? :tty : :notty),
      :unknown == state.total ? :infinite : :finite
    ]
    state.scope = state.settings
    state.scope_at.each do |s|
      begin
        state.scope = state.scope[s]
      rescue NoMethodError
        raise StandardError, "Invalid configuration: #{state.scope_at.join('.')} "+
                             "(Can't resolve: #{state.scope_at[state.scope_at.index(s)-1]})"
      end
    end
    state.scope_hash = scope_hash
    state.scope
  end

  # Hook at_exit to ensure cleanup when we get interrupted
  def hook_exit
    return if @@exit_hooked
    if scope.template.exit
      at_exit do
        exit!
      end
    end
    @@exit_hooked = true
  end

  # This prints the close-template which normally prints a newline.
  # Be a good citizen, always close your PowerBars!
  def close
    scope.output.call(scope.template.close) unless scope.template.close.nil?
    state.closed = true
  end

  # Update state (and settings) without printing anything.
  def update(opts={})
    state.merge!(opts)
    state.time_start ||= Time.now
    state.time_now = Time.now

    @rate ||= PowerBar::Rate.new(state.time_now, 
                                         state.settings.rate_sample_window,
                                         state.settings.rate_sample_max_interval)
    @rate.append(state.time_now, state.done)
  end

  # Display the PowerBar.
  def show(opts={})
    if scope.interval <= Time.now - state.time_last_show
      update(opts)
      hook_exit

      state.time_last_show = Time.now
      state.closed = false
      scope.output.call(scope.template.pre)
      scope.output.call(render)
      scope.output.call(scope.template.post)
    end
  end

  # Render the PowerBar and return as a string.
  def render(opts={})
    update(opts)
    render_template
  end

  # Remove the PowerBar from the screen.
  def wipe
    scope.output.call(scope.template.wipe)
  end

  # Render the actual bar-portion of the PowerBar.
  # The length of the bar is determined from the template.
  # Returns nil if the bar-length would be == 0.
  def bar
    return nil if state.total.is_a? Symbol
    blank   = render_template(:main, skip=[:bar])
    twid    = state.scope_at[0] == :tty ? terminal_width() : scope.line_width
    barlen  = [twid - blank.gsub(STRIP_ANSI, '').length, 0].max
    done    = state.done
    total   = state.total
    barchar = scope.template.barchar
    padchar = scope.template.padchar
    fill = [0,[(done.to_f/total*barlen).to_i,barlen].min].max
    thebar = barchar * fill + padchar * [barlen - fill,0].max
    thebar.length == 0 ? nil : thebar
  end

  def h_bar
    bar
  end

  def msg
    state.msg
  end

  def h_msg
    msg
  end

  def eta
    (state.total - state.done) / rate
  end

  # returns nil when eta is < 1 second
  def h_eta
    1 < eta ? humanize_interval(eta) : nil
  end

  def elapsed
    e = (state.time_now - state.time_start).to_f
  end

  def h_elapsed
    humanize_interval(elapsed)
  end

  def percent
    return 0.0 if state.total.is_a? Symbol
    state.done.to_f/state.total*100
  end

  def h_percent
    sprintf "%d", percent
  end

  def rate
    @rate.avg
  end

  def h_rate
    humanize_quantity(rate.round(1))
  end

  def total
    state.total
  end

  def h_total
    humanize_quantity(state.total)
  end

  def done
    state.done
  end

  def h_done
    humanize_quantity(state.done)
  end

  def terminal_width
    ANSI::Terminal.terminal_width
  end

  private
  def state
    @state
  end

  # Cap'n Hook
  def exit!
    return if state.closed
    scope.output.call(scope.template.exit) unless scope.template.exit.nil?
  end

  def render_template(tplid=:main, skip=[])
    tpl = scope.template[tplid]
    skip.each do |s|
      tpl = tpl.gsub(/\$\{([^<]*)<#{s}>([^}]*)\}/, '\1\2')
    end
    tpl.gsub(/\${[^}]+}/) do |var|
      sub = nil
      r = var.gsub(/<[^>]+>/) do |t|
        t = t[1..-2]
        begin
          sub = self.send(('h_'+t).to_sym)
        rescue NoMethodError => e
          raise NameError, "Invalid token '#{t}' in template '#{tplid}'"
        end
      end[2..-2]
      sub.nil? ? '' : r
    end
  end

  HQ_UNITS = %w(b k M G T).freeze
  def humanize_quantity(number, format='%n%u', base=1024)
    return nil if number.nil? 
    return nil if number.is_a? Float and (number.nan? or number.infinite?)
    return number if number.to_i < base

    max_exp  = HQ_UNITS.size - 1
    number   = Float(number)
    exponent = (Math.log(number) / Math.log(base)).to_i
    exponent = max_exp if exponent > max_exp
    number  /= base ** exponent

    unit = HQ_UNITS[exponent]
    return format.gsub(/%n/, number.round(1).to_s).gsub(/%u/, unit)
  end

  def humanize_interval(s)
    return nil if s.nil? or s.infinite?
    sprintf("%02d:%02d:%02d", s / 3600, s / 60 % 60, s % 60)
  end

  class Rate < Array
    attr_reader :last_sample_at
    def initialize(at, len, max_interval=10, interval_step=0.1)
      super([])
      @last_sample_at = at
      @sample_interval = 0
      @sample_interval_step = interval_step
      @sample_interval_max = max_interval
      @counter = 0
      @len = len
    end

    def append(at, v)
      return if @sample_interval > at - @last_sample_at
      @sample_interval += @sample_interval_step if @sample_interval < @sample_interval_max

      rate = (v - @counter) / (at - @last_sample_at).to_f
      return if rate.nan?

      @last_sample_at = at
      @counter = v

      self << rate
      if length > @len
        shift
      end
    end

    def sum
      inject(:+).to_f
    end

    def avg
      sum / size
    end
  end
end

