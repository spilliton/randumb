# randumb

randumb is a ruby gem that allows you to pull random records from ActiveRecord...fast!

This gem requires rails 3 or greater.

## Example Usage

``` ruby
## randumb works the same as active records "all, first, and last" methods
## with no params, it will pull back one random record
Artist.random
## you can also put it at the end of scopings and relations
## passing an integer will pull that many records back in random order (unless your query brings back less records)
Artist.has_views.includes(:albums).random(10)
```