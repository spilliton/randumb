# randumb

randumb is a ruby gem that allows you to pull random records from ActiveRecord...fast!

This gem requires ActiveRecord version 3.0.0 or greater.

I built this for use on [Compare Vinyl][comparevinyl].  Check out the homepage to see it in action :)

## Example Usage

``` ruby
## randumb works the same as active records "all, first, and last" methods
## with no params, it will pull back one random record
Artist.random
## you can also put it at the end of scopings and relations
## passing an integer will pull that many records back in random order (unless your query brings back less records)
Artist.has_views.includes(:albums).random(10)
```

``` ruby
## returns a record if called without parameters
artist = Artist.random ## instead of artist = Artist.random.first

## returns an array if called with parameters
artists = Artist.random(3)  ## returns an array
artists = Artist.random(1)  ## returns an array
```

## Install 

``` ruby
## Add the following to you Gemfile
gem 'randumb'
## Run this
bundle install
```


[comparevinyl]: http://www.comparevinyl.com/
