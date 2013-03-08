#!/usr/bin/env ruby

require 'optparse'

options = {}
optparse = OptionParser.new { |opts|
  opts.banner = "Usage: spark-git.rb [options] dir"

  options[:weeks] = 26
  weeks_text = 'The number of weeks to look backward (default: 26)'
  opts.on( '--weeks WEEKS', weeks_text) { |weeks|
    options[:weeks] = weeks.to_i
  }
}

optparse.parse!

class Time
  def week
    strftime('%U').to_i
  end
end

WEEK_SECONDS = 7 * 24 * 60 * 60

def time_between?(t, min, max)
  (t.year == min.year && t.week >= min.week) || (t.year == max.year && t.week <= max.week)
end

def git_hist(dir, ago_secs)
  now = Time.now
  min = now - ago_secs
  `git --git-dir=#{dir}/.git --work-tree=#{dir} log --branches=* --author='#{ENV['USER']}' --since="#{ago_secs/WEEK_SECONDS} weeks ago" --pretty=format:'%at'`.split(" ").map {|line|
    t = Time.at(line.split(' ').last.to_i)
    time_between?(t, min, now) ? t : nil
  }.compact.group_by {|x| x.strftime('%G%U') }.inject({}) {|res, (k, v)|
    res[k] = v.size
    res
  }
end

def spark_vals(weeks, commits, min)
  (0...weeks).map {|i|
    commits[(min + WEEK_SECONDS * (i+1)).strftime('%G%U')] || 0
  }.join(',')
end

def stats_since(dir, ago)
  ago_secs = ago * 60 * 60 * 24 * 7
  spark_vals(ago, git_hist(dir, ago_secs), Time.now - ago_secs)
end

print `spark #{stats_since(ARGV[0], options[:weeks])}`

