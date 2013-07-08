#!/usr/bin/env ruby

require 'chronic'
require 'trollop'
require 'yaml'

# config
actions = ['timer', 'total']
$options = {:default_time => '30', :pause => '5'}

class Stretch < String
  def name
    self.split(':').first
  end

  def time
    t = self.split(':')[1]
    t = $options[:default_time] if t.nil?
    t.to_i
  end
end


# Time string to seconds
def parse_time(string)
  string.to_i
  # if string.end_with?('seconds')
  #   string.slice! 'seconds'
  #   return string.strip.to_i
  # elsif string.end_with?('minutes')
  #   string.slice! 'minutes'
  #   return string.strip.to_i * 60
  # end
end

def pretty_time(seconds)
  h = seconds/3600
  m = seconds.modulo(3600)/60
  s = seconds.modulo(60)
  h_s = h > 0 ? "#{h}h " : ""
  m_s = m > 0 ? "#{m}m " : ""
  "#{h_s}#{m_s}#{s}s"
end

def countdown(seconds, interval=5, deliminator=', ')
  seconds.downto(1) do |n|
    if n.modulo(interval).zero? or [1, seconds].include?(n)
      print(n, deliminator)
    end
    sleep(1)
  end
end

def timer(schedule)
  (0...schedule.length).each do |i|
    #  # deal with string shorthand by promoting to simple dict
    stretch = schedule[i]
    next_stretch = schedule[i+1]

    next_clause = i+1 < schedule.length ? " [next:#{next_stretch.name}]" : ""

    puts "#{stretch.name}#{next_clause}"
    print " > "
    countdown(stretch.time)
    puts "fin."
    system "mplayer -really-quiet #{$options[:sound_file]} &" if $options.has_key?(:sound_file)
    sleep($options[:pause])
  end
end

def total(schedule)
  puts pretty_time(schedule.map(&:time).inject(:+) + schedule.length * $options[:pause])
end

def validate
  parse_time($options[:default_time])
  if $options.has_key?(:sound_file)
    raise IOError if !File.exists?(File.expand_path($options[:sound_file]))
  end
end

opts = Trollop::options do
  opt :file, "Specify stretches file location", :default => File.expand_path('~/.stretches.yaml')
  opt :action, "What to do.", :default => 'timer'
end
Trollop::die :file, "must exist" unless File.exist?(opts[:file])
Trollop::die :action, "must be one of: #{actions.join(', ')}" unless actions.include?(opts[:action])


y = YAML.load_file(opts[:file])
config = y['config']
schedule = y['schedule'].map{ |s| Stretch.new(s) }

# update options from YAML
$options[:default_time] = config.fetch('default-time', $options[:default_time])
$options[:pause] = config.fetch('pause', $options[:pause]).to_i
$options[:sound_file] = config['sound-file'] if config.has_key?('sound-file')


# validate
validate


case opts[:action]
when 'timer'
  timer(schedule)
when 'total'
  total(schedule)
else
  puts "Error!"
  exit(1)
end

