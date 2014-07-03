#!/usr/bin/env ruby

require 'optparse'
require 'shellwords'
require 'ostruct'

USAGE = "Usage: ruby spark-git.rb [--unit=(days|weeks) --range=int --author=name] directories"
DAY_SECONDS = 24 * 60 * 60
WEEK_SECONDS = 7 * DAY_SECONDS
DAY_FMT_STRING = '%G%j'
WEEK_FMT_STRING = '%G%U'

options = {}
optparse = OptionParser.new { |opts|
  opts.banner = USAGE

  options[:config] = OpenStruct.new
  options[:config].fmt = WEEK_FMT_STRING
  options[:config].secs = WEEK_SECONDS
  options[:config].unit_name = 'week'

  opts.on( '--unit=[days|weeks]') { |unit|
    raise RuntimeError unless unit == 'days' || unit == 'weeks'
    if unit == 'days' then
      options[:config].fmt = DAY_FMT_STRING
      options[:config].secs = DAY_SECONDS
      options[:config].unit_name = 'day'
    end
  }

  options[:config].range = 26
  range_text = 'The number of days/weeks to look backward (default: 26)'
  opts.on( '--range=NUMBER', range_text) { |range|
    options[:config].range = range.to_i
  }

  options[:config].author = ENV['USER']
  name_text = 'The author name to search git logs for'
  opts.on( '--author=NAME', name_text) { |name|
    options[:config].author = name
  }
}

FLAGS = options[:config]

optparse.parse!

class Time
  def week
    strftime(WEEK_FMT_STRING).to_i
  end

  def day
    strftime(DAY_FMT_STRING).to_i
  end
end

def time_between?(t, min, max)
  (t.year == min.year &&
   t.send(FLAGS.unit_name) >= min.send(FLAGS.unit_name)) ||
   (t.year == max.year && t.send(FLAGS.unit_name) <= max.send(FLAGS.unit_name))
end

def git_cmd(dir, ago_secs)
  cmd = "git --git-dir=#{Shellwords.escape(dir)}/.git --work-tree=#{Shellwords.escape(dir)} log --branches=* --author=\"#{FLAGS.author}\" --since=\"#{ago_secs/FLAGS.secs} #{FLAGS.unit_name}s ago\" --pretty=format:'%at' 2> /dev/null"
  #puts cmd
  `#{cmd}`
end

def git_hist(dir, ago_secs)
  now = Time.now
  min = now - ago_secs
  git_cmd(dir, ago_secs).split(" ").map {|line|
    t = Time.at(line.split(' ').last.to_i)
    time_between?(t, min, now) ? t : nil
  }.compact.group_by {|x| x.strftime(FLAGS.fmt) }.inject({}) {|res, (k, v)|
    res[k] = v.size
    res
  }
end

def spark_vals(units, commits, min)
  (0...units).map {|i|
    commits[(min + FLAGS.secs * (i+1)).strftime(FLAGS.fmt)] || 0
  }
end

def stats_since(dir, ago)
  ago_secs = ago * FLAGS.secs
  spark_vals(ago, git_hist(dir, ago_secs), Time.now - ago_secs)
end

aggregate = ARGV.map {|dir|
  stats_since(dir, FLAGS.range)
}.transpose.map{|x| x.reduce(:+)}.join(',')


if aggregate.empty?
  puts USAGE
  exit
end
out = `spark #{aggregate}`
if $?.success?
  print out
else
  puts USAGE
end

