### 0.6.0

* Dropping support for ActiveRecord 3, delegate method issue fix, deprecation fixes

### 0.5.2

* Fixing [bug](https://github.com/spilliton/randumb/issues/31) that caused randumb to override default scopes on models

### 0.5.1

* Fixing [bug](https://github.com/spilliton/randumb/issues/35) that occurred when using ActiveRecord 5.x

### 0.5.0

* Adding ```order_by_rand``` and ```order_by_rand_weighted``` scopes
* Depricating ```random```, ```random_weighted```, and random_weighted dynamic scopes

### 0.4.0

* Support for Active Record 4

### 0.3.1

* Added support for PostGIS

### 0.3.0

* Added random_weighted() (thanks mceachen)
* Added random_by_id_shuffle() to fix issue with uniq in postgres and provide some options
