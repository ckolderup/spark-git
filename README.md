## spark-git.rb

spark-git.rb draws a sparkline of git commits bucketed by week to show you
at a glance how active you've been in a git repo (or a set of git repos).

Usage: ruby spark-git.rb [--weeks=<weeks>] directories
Defaults to 26 weeks (roughly half a year)

## Before you do anything

You have to install Zach Holman's excellent [spark](http://github.com/holman/spark)!

If you have Mac OS X and homebrew, you can just `brew install spark`. Whew!

## Ways to use it

I have this script set up in two places in my bashrc:

1) **When `cd`ing into the root of a git repo**

```
cd() {
  if [[ $@ == '-' ]]; then
    builtin cd "$@" > /dev/null  # We'll handle pwd.
  else
    builtin cd "$@"
  fi
  if ls .git &> /dev/null; then
    echo -e "   \033[1;34m"`~/bin/spark-git.rb . `"\033[0m"
  fi
}
```

2) **When I load my bashrc**: In order to see my recent overall activity, I run this command whenever my bashrc executes:

```
echo -e "\033[1;31m"`ruby ~/bin/spark-git.rb ~/src/*`"\033[0m"'
```

This acts as a primary motivating factor and gives me a chance to see whether or not I'm keeping up with my desire to be spending time writing code!
