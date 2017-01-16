# randumb

[![Gem Version](https://badge.fury.io/rb/randumb.png)](http://badge.fury.io/rb/randumb)
[![Build Status](https://secure.travis-ci.org/spilliton/randumb.png?branch=master)](http://travis-ci.org/spilliton/randumb)
[![Code Climate](https://codeclimate.com/github/spilliton/randumb.png)](https://codeclimate.com/github/spilliton/randumb)

randumb is a ruby gem that allows you to easily pull random records from your database of choice.

Requires ActiveRecord >= 3.0.0 and supports SQLite, MySQL and Postgres/PostGIS (PRs welcome for other DB support).

## Install

``` ruby
# Add the following to you Gemfile
gem 'randumb'

# Update your bundle
bundle install
```

## Usage

The most common usage is a scope you can chain along like any other:

``` ruby
Artist.order_by_rand.first # a random Artist if there are any, otherwise nil
Artist.order_by_rand.limit(3).all  # an array of three Artists picked at random
Artist.order_by_rand.limit(1).all  # an array containing one random Artist
```

### How It Works

randumb simply tacks an additional ```ORDER BY RANDOM()``` (or ```RAND()``` for mysql) to your query.

## Advanced Usage

### Stacking the Deck

You can use the ```order_by_rand_weighted``` scope to favor certain records more than others.

For example, if you want to favor higher-rated Movies, and your
Movie model has a numeric ```score``` column, you can do any of the the following:

``` ruby
Movie.order_by_rand_weighted(:score).first
# returns 1 random movie by:
# select * from movies ORDER BY (score * RANDOM() DESC) LIMIT 1

Movie.order_by_rand_weighted(:score).limit(10).all
# returns an array of up to 10 movies and executes:
# select * from movies ORDER BY (score * RANDOM() DESC) LIMIT 10
```

### Planting A Seed

If you wish to seed the randomness so that you can have predictable outcomes, provide an optional integer seed to any of randumb's scopes:

``` ruby
# Assuming no no records have been added between calls
# These will return the same 2 artists in the same order both times
Artist.order_by_rand(seed: 123).limit(2)
Artist.order_by_rand(seed: 123).limit(2)
```

One use case for this scope is when you are paginating through random records.

### Depricated Syntax

A few methods will be going away in randumb 1.0 due to them not really following current active record conventions:

``` ruby
# working like the active record "all, first, and last" methods and passing limit as param
Artist.has_views.includes(:albums).where(["created_at > ?", 2.days.ago]).random(10)
# dynamic finders for weighted methods
Artist.random_weighted_by_views
```

### Random By Id Shuffle

The adventurous may wish to try randumb's earlier algorithm for random record selection.
You cannot apply weighting when using this method and limits/orders also behave a little differently.

``` ruby
# gimmie 5 random artists that are in the top 100 most viewed
artists = Artist.limit(100).order("view_count DESC").random_by_id_shuffle(5)

# Executes:
# select artist.id from artists ORDER BY view_count DESC LIMIT 100
# in ruby:  artist_ids = ids.shuffle[0..4]
# select * from artists WHERE id in (artist_ids)
```

## A Note on Performance

As stated above, by default, randumb uses a simple approach of applying an order by random() statement to your query.  In many sets, this performs well enough to not really be a big deal.  However, as many blog posts and articles will note, the database must generate a random number for each row matching the scope and this can result in rather slow queries for large result sets.  The last time I tested randumb on a test data set with 1 million rows (with no scopes) it took over 2 seconds.

In earlier versions of randumb I tried to alleviate this by doing two db queries.  One to select the possibly IDs into an array, and a second with a randomly selected set of those ids.  This was sometimes faster in very high data sets, however, for most sizes I tested, it did not perform significatly better than ORDER BY RAND() and it had the possibility of running out of memory due to selecting all the ids into into a ruby array.

If you are noticing slow speeds on your random queries and you have a very very large database table, my advice is to scope down your query to a subset of the table via an indexed scope.  Ex:  ```Artist.where('views > 10').order_by_rand.first```  This will result in less calls to RAND() and a faster query.  You might also experiment with the old method by using ```random_by_id_shuffle``` and gauge the resulting speeds.

## ActiveRecord Caching

By default, ActiveRecord keeps a cache of the queries executed during the current request. If you call `order_by_rand` multiple times on the same model or scope, you will end up with the same SQL query again, which causes the cache to return the result of the last query. You will see the following in your log if this happens:

```
Artist Load (0.3ms)  SELECT "artists".* FROM "artists" ORDER BY RANDOM() LIMIT 1
CACHE (0.0ms)  SELECT "artists".* FROM "artists" ORDER BY RANDOM() LIMIT 1
```

Fortunately, there is an easy workaround: Just wrap your query in a call to ```uncached```, e.g. ```Artist.uncached { Artist.order_by_rand.first }```.

## Why

I built this for use on [Compare Vinyl][comparevinyl].  Check out the homepage to see it in action :)

[comparevinyl]: http://www.comparevinyl.com/
