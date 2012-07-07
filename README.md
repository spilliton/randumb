# randumb

[![Build Status](https://secure.travis-ci.org/spilliton/randumb.png?branch=master)](http://travis-ci.org/spilliton/randumb)

randumb is a ruby gem that allows you to easily pull random records from your database of choice

Requires ActiveRecord >= 3.0.0 and supports SQLite, MySQL and Postgres

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
Artist.has_views.includes(:albums).where(["created_at > ?", 2.days.ago]).random(10)

If only 5 records matched the conditions specified above, randumb will return an array with those 5 records in random order (as opposed to 10 records with duplicates).
```

### How It Works

randumb simply tacksan additional ```ORDER BY RANDOM()``` (or ```RAND()``` for mysql) to your query.

It will have the *least* amount of sort precedence if you include other orders in your scope.

## Advanced Usage

### Stacking the Deck

You can use the ```random_weighted``` method to favor certain records more than others.

For example, if you want to favor higher-rated Movies, and your
Movie model has a numeric ```score``` column, you can do any of the the following: 

``` ruby
Movie.random_weighted(:score)      
Movie.random_weighted_by_score     
# returns 1 random movie by:
# select * from movies ORDER BY (score * RANDOM() DESC)

Movie.random_weighted(:score, 10)  
Movie.random_weighted_by_score(10) 
# returns an array of up to 10 movies and executes:
# select * from movies ORDER BY (score * RANDOM() DESC) LIMIT 10
```

### Pick Your Poison

The adventurous may wish to try randumb's earlier algorithm for random record selection: ```random_by_id_shuffle```.

You cannot apply weighting when using this method and limits/orders also behave a little differently:

``` ruby
# gimmie 5 random artists that are in the top 100 most viewed
artists = Artist.limit(100).order("view_count DESC").random_by_id_shuffle(5)

# Executes:
# select artist.id from artists ORDER BY view_count DESC LIMIT 100
# in ruby:  artist_ids = ids.shuffle[0..4]
# select * from artists WHERE id in (artist_ids)
```

Compare this to the default ```random()``` which will use the lesser of the limits you provide and apply ```ORDER BY RANDOM()``` sorting after any other orders you provide.

``` ruby
# (belligerently) Gimme the top 5 artists and I'll pointlessly provide a limit of 100!
# Plus I want artists with the same view count to be sorted randomly!
# This clearly a silly thing to do...
artists = Artist.limit(100).order("view_count DESC").random(5)

# Executes:
# select * from artists ORDER BY view_count DESC, RANDOM() LIMIT 5
```

## A Note on Performance

As stated above, by default, randumb uses a simple approach of applying an order by random() statement to your query.  In many sets, this performs well enough to not really be a big deal.  However, as many blog posts and articles will note, the database must generate a random number for each row matching the scope and this can result in rather slow queries for large result sets.  The last time I tested randumb on a test data set with 1 million rows (with no scopes) it took over 2 seconds.

In earlier versions of randumb I tried to alleviate this by doing two db queries.  One to select the possibly IDs into an array, and a second with a randomly selected set of those ids.  This was sometimes faster in very high data sets, however, for most sizes I tested, it did not perform significatly better than ORDER BY RAND() and it had the possibility of running out of memory due to selecting all the ids into into a ruby array.

If you are noticing slow speeds on your random queries and you have a very very large database table, my advice is to scope down your query to a subset of the table via an indexed scope.  Ex:  ```Artist.where('views > 10').random```  This will result in less calls to RAND() and a faster query.  You might also experiment with the old method by using ```random_by_id_shuffle``` and gauge the resulting speeds.

## Why

I built this for use on [Compare Vinyl][comparevinyl].  Check out the homepage to see it in action :)

[comparevinyl]: http://www.comparevinyl.com/

## Changelog

### 0.3.0

* Added random_weighted() (thanks mceachen)
* Added random_by_id_shuffle() to fix issue with uniq in postgres and provide some options
