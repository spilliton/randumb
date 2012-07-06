# randumb

[![Build Status](https://secure.travis-ci.org/spilliton/randumb.png?branch=master)](http://travis-ci.org/spilliton/randumb)

randumb is a ruby gem that allows you to easily pull random records

Requires ActiveRecord 3.0.0 or greater

## Install 

``` ruby
# Add the following to you Gemfile
gem 'randumb'
# Update your bundle
bundle install
```

## Usage

``` ruby
Artist.random # a random Artist if there are any, otherwise nil
Artist.random(3)  # an array of three Artists picked at random
Artist.random(1)  # an array containing one random Artist
```

### Scopes
``` ruby
# randumb works like the active record "all, first, and last" methods
# so you tack it at the end of scopes and relations
Artist.has_views.includes(:albums).where(["created_at > ?", 2.days.ago]).random(10)

# if only 5 records met the where conditions specified above 
# randumb will return an array with those 5 records in random order
# (as opposed to 10 records with random duplicates)
```

### How It Works

randumb works by tacking on an additional ORDER BY RANDOM() to your query.

It will have the least amount of sort precedence if you are already including other ordering.

### Stacking the Deck

You can use ```random_weighted``` to favor certain instances more than others.

If you want to favor showing higher-rated Movies, for example, and your
Movie model has a numeric ```score``` column, you can do any of the the following: 

``` ruby
Movie.random_weighted(:score)      # 1 movie
Movie.random_weighted_by_score     # 1 movie
Movie.random_weighted(:score, 10)  # array of 10 movies
Movie.random_weighted_by_score(10) # array of 10 movies
```

Higher-scored movies will be more likely to be returned than lower-scored movies, in proportion to their ```score``` column.

### Pick Your Poison

If you wish to use randumb's prior algorithm, you may use the ```random_by_id_shuffle``` method.

You cannot apply weighting when using this method.  Limits and orders also behave a little differently:

``` ruby
# I want 5 random artists that are in the top 100 most viewed
artists = Artist.limit(100).order("view_count DESC").random_by_id_shuffle(5)

# Executes:
# select artist.id from artists ORDER BY view_count DESC LIMIT 100
# ...randomly choose 5 ids from the result in ruby...
# select * from artists WHERE id in (12, 2334, ...)
```

Compare this to the default ```random()``` method which will use the lesser of the limits you provide, and apply order by random() sorting after any other sorts you provide.

``` ruby
# I want the top 5 artists and I'm pointlessly providing a limit of 100
# plus I want artists with the same view count to be sorted randomy.
# This is *clearly* a silly thing to do.
artists = Artist.limit(100).order("view_count DESC").random(5)

# Executes:
# select * from artists ORDER BY view_count DESC, RANDOM() LIMIT 100
```

## A Note on Performance

As stated above, by default, randumb uses the simple approach of applying an order by random() statement to your query.  In most sets, this performs well enough to not really be a big deal.  However, as many blog posts and articles will note, the database must generate a random number for each row matching the scope and can result in rather slow queries in large sets.  The last time I tested randumb on a test data set with 1 million rows (with no scopes) it took over 2 seconds.

In earlier versions of randumb I tried to alleviate this by doing two db queries.  One to select the possibly IDs into an array, and a second with a randomly selected set of those ids.  This was sometimes faster in very high data sets, however, for almost all sizes I tested, it did not perform significatly better than ORDER BY RAND() and had the possibility of running out of memory due to selecting all the ids into into a ruby array.

If you are noticing slow speeds on your random queries and you have a very very large database table, my advice is to scope down your query to a subset of the table via an indexed scope.  Ex:  ```Artist.where('views > 10').random```  This will result in less calls to RAND() and a much faster query.  You might also experiment with the old method by using ```random_by_id_shuffle```

## Why

I built this for use on [Compare Vinyl][comparevinyl].  Check out the homepage to see it in action :)

[comparevinyl]: http://www.comparevinyl.com/

## Changelog

### 0.3.0 (to be pushed to rubygems soon)

* Added ```random_weighted``` 
* Adding random_by_id_shuffle() 
* Bugfix for #7
