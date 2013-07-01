#!/usr/bin/env ruby

#
# Generate a plan for today
#

require 'date'


$plans_location = File.expand_path("~/plans/")
$config_location = File.expand_path("~/.plan/")
$yesterday_exlude = ['teeth', 'stretch', 'supplements', 'anki reps']
                     
class String
  def filesub(var, filename)
    "Try to substitute {{var}} -> contents of file, checking for existence"
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

  def promote
    "Promote unescaped headings"
    self.gsub(/^(\*+) ()/, "\\1* ")
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

# Start with daily template
plan = IO.read(File.join(templates_location, "daily.org"))

# Date
plan.sub('date', today)

# Add yesterday's unfinished tasks (promoting headings)
yesterday_template = File.join(templates_location, "yesterday.org")
yesterday_plan = File.join($plans_location, "#{yesterday}.org")
yesterday_text = IO.read(yesterday_template).filesub('tasks', yesterday_plan) { |line|
  line.include?(' TODO ') and $yesterday_exlude.none? { |s|
    line.downcase.include?(s.downcase)
  } and !line.strip[0] == '#'
}.promote.unescape
plan.sub('yesterday', yesterday_text)

# If Friday, add weekly
weekly_filename = File.join(templates_location, "weekly.org")
plan.filesub('weekly', weekly_filename) if Date.today.friday?

# Add Google Calendar events
events = [`google calendar today | tail -n+3`,
          `google --cal="Fitness" calendar today | tail -n+3`,
          `google --cal="Revision" calendar today | tail -n+3`].join
plan.sub('events', events)


# Otherwise, get rid of all other days
plan.cleantags


if ARGV.length == 0
  filename = File.join($plans_location, "#{today}.org")
  initial_filename = File.join($plans_location, ".#{today}.initial.org")

  if File.exists?(filename)
    puts "Error: #{filename} already exists!"
  else
    puts "Plan generated, saving to file: #{filename}."
    IO.write(filename, plan)
    IO.write(initial_filename, plan)
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

