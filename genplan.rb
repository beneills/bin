#!/usr/bin/env ruby

#
# Generate a plan for today
#

require 'date'


$plans_location = File.expand_path("~/plans/")
$config_location = File.expand_path("~/.plan/")
$yesterday_exlude = ['teeth', 'stretch', 'supplements', 'anki reps']
                     
class String
  def filesub(var, filename=nil)
    "Try to substitute {{var}} -> contents of file, checking for existence"
    templates_location = File.join($config_location, "templates")
    filename = File.join(templates_location, "#{var}.org") if filename.nil?
    return unless File.exists? filename
    replacement = (File.open(filename) { |f|
                     f.select { |line|
                       if block_given?
                         yield line
                       else
                         true
                       end
                     }
                   }.join().chomp if File.exists?(filename)) or ""
    self.sub(var, replacement)
  end

  def sub(var, replacement)
    self.gsub!(/{{#{var}}}/, replacement)
  end

  def cleantags
    self.gsub!(/^{{.*?}}\n/, "")
    self.gsub!(/{{.*?}}/, "")
  end

  def promote_to(depth)
    "e.g. '**** hello' -> '** hello' for depth=2"
    self.gsub(/^(\*+) /, "** ")
  end

  def unescape
    "unescape asterisks"
    self.gsub(/\\\*/, "*")
  end
end

def usage
  puts "Usage: #{$0} (-t | -h)"
  puts "  --help, -h: show this usage"
  puts "  --test, -t: output to stdout"
end


templates_location = File.join($config_location, "templates")
today = Date.today.strftime("%F")
yesterday = (Date.today - 1).strftime("%F")

# Start with default template
plan = IO.read(File.join(templates_location, "default.org"))

# Add daily events
plan.filesub('daily')

# Date
plan.sub('date', today)

# Add yesterday's unfinished tasks (promoting headings)
yesterday_template = File.join(templates_location, "yesterday.org")
yesterday_plan = File.join($plans_location, "#{yesterday}.org")
if File.exists? yesterday_plan
  yesterday_text = IO.read(yesterday_template).filesub('tasks', yesterday_plan) { |line|
    line.include?(' TODO ') and $yesterday_exlude.none? { |s|
      line.downcase.include?(s.downcase)
    } and line.strip[0] != '#'
  }.promote_to(2).unescape
  plan.sub('yesterday', yesterday_text)
end

# If Friday, add weekly
plan.filesub('weekly') if Date.today.friday?

# If end of month, add monthly
plan.filesub('monthly') if Date.today.cweek.modulo(4).zero? and Date.today.friday?

# Add Google Calendar events
events = [`google calendar today | tail -n+3`,
          `google --cal="Fitness" calendar today | tail -n+3`,
          `google --cal="Revision" calendar today | tail -n+3`].join
plan.sub('events', events)


# Otherwise, get rid of all other days
plan.cleantags


if ARGV.length == 0
  link = File.join($plans_location, "today.org")
  filename = File.join($plans_location, "#{today}.org")
  initial_filename = File.join($plans_location, ".#{today}.initial.org")

  if File.exists?(filename)
    puts "Error: #{filename} already exists!"
  else
    puts "Plan generated, saving to file: #{filename}."
    IO.write(filename, plan)
    IO.write(initial_filename, plan)
    File.delete(link)
    File.symlink(filename, link)
  end
elsif ARGV.length == 1 and ['-t', '--test'].include?(ARGV.first)
  print plan
elsif ARGV.length == 1 and ['-h', '--help'].include?(ARGV.first)
  usage
  exit 0
else
  usage
  exit 1
end

