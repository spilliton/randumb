# randumb

[![Build Status](https://secure.travis-ci.org/spilliton/randumb.png?branch=master)](http://travis-ci.org/spilliton/randumb)

randumb is a ruby gem that allows you to easily pull random records via ActiveRecord

Requires ActiveRecord 3.0.0 or greater

## Usage

``` ruby
Artist.random # returns a random instance of Artist if there are any, otherwise nil
Artist.random(3)  # returns an array of three Artists picked at random
Artist.random(1)  # returns an array containing one random Artist
```

### Scopes
``` ruby
# randumb works like the active record "all, first, and last" methods
# so you can put it at the end of scopes and relations
Artist.has_views.includes(:albums).where(["created_at > ?", 2.days.ago]).random(10)

# in the prior example, if only 5 records met the where conditions, 
# randumb will return an array with those 5 records in random order
```

randumb works by tacking on an additional RANDOM() order to the scope.
It will have the least amount of sort precedence if you are already including other ordering.

### Stacking the Deck

You can use ```random_weighted``` to favor certain instances more than others.

If you want to favor showing higher-rated Movies, for example, and your
Movie model has a numeric ```score``` column, you can use ```Movie.random_weighted_by_score```.

Higher-scored movies will be more likely to be returned than lower-scored movies, in proportion to their ```score```.

## Install 

``` ruby
# Add the following to you Gemfile
gem 'randumb'
# Update your bundle
bundle install
```

## A Note on Performance

As stated above, randumb uses the simple approach of applying an order by random() statement to your query.  In most sets, this performs well enough to not really be a big deal.  However, as many blog posts and articles will note, the database must generate a random number for each row matching the scope and can result in rather slow queries in large sets.  The last time I tested randumb on a test data set with 1 million rows (with no scopes) it took over 2 seconds.

In earlier versions of randumb I tried to alleviate this by doing two db queries.  One to select the possibly IDs into an array, and a second with a randomly selected set of those ids.  This was sometimes faster in very high data sets, however, for almost all sizes I tested, it did not perform significatly better than order by rand() and had the possibility of running out of memory due to selecting all the ids into into a ruby array.

If you are noticing slow speeds on your random queries and you have a very very large database table, my advice is to scope down your query to a subset of the table via an indexed scope.  Ex:  ```Artist.where('views > 10').random```  This will result in less calls to rand() and a much faster query.

## Why

I built this for use on [Compare Vinyl][comparevinyl].  Check out the homepage to see it in action :)

[comparevinyl]: http://www.comparevinyl.com/

## Changelog

### 0.3.0

* Added ```random_weighted``` (to be pushed to rubygems soon)
