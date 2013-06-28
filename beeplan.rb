#!/usr/bin/env ruby

#
# To be run daily; it checks for yesterday's plan file
#
# Maintain a plans directory with files 
#

require 'date'


$plans_location = File.expand_path("~/plans/")
$plan_extension = ".org"
$plans_goal_slug = "plan"


yesterday = (Date.today - 1).strftime("%F")
filename = File.join($plans_location, "#{yesterday}#{$plan_extension}")

if File.exists?(filename) and !File.zero?(filename)
  print "Uploading plan for #{yesterday}..."
  `beemind #{plans_goal_slug} 1 "beeplan.rb: found plan for #{yesterday}"`
  puts "done"
else
  puts "Could not find a plan file for yesterday (checked #{filename})"
end
