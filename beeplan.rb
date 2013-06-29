#!/usr/bin/env ruby

#
# To be run daily; it checks for yesterday's plan file
#
# Maintain a plans directory with files 
#

require 'date'


$plans_location = File.expand_path("~/plans/")
$plans_goal_slug = "plan"


yesterday = (Date.today - 1).strftime("%F")
filename = File.join($plans_location, "#{yesterday}.org")
initial_filename = File.join($plans_location, ".#{yesterday}.initial.org")

if File.exists?(filename) and
    File.exists?(initial_filename) and
    !`diff #{filename} #{initial_filename}`.empty?
  todo = File.open(filename, 'r').count { |line| line.include?(' TODO ') }
  done = File.open(filename, 'r').count { |line| line.include?(' DONE ') }
  msg = "beeplan.rb: #{yesterday}: #{done}/#{todo+done} DONE"
  print(msg, '...')
  `beemind #{$plans_goal_slug} 1 "#{msg}"j`
  puts "done"
else
  puts "Could not plan file (or initial file) for yesterday (checked #{filename})"
end
