$:.unshift '.'; require File.dirname(__FILE__) + '/test_helper'

class BenchmarkTest < Test::Unit::TestCase


  TIMES_PER_TEST = 20


  TESTS = [
    {:total_rows => 10000000, :request_sizes => [1, 10, 50, 100, 250]},
    {:total_rows => 1000000, :request_sizes => [1, 10, 50, 100, 250]},
    {:total_rows => 100000, :request_sizes => [1, 10, 50, 100, 250]},
    {:total_rows => 10000, :request_sizes => [1, 10, 50, 100, 250]}
  ]




  def ensure_artists(num)
    artist_count = Artist.count

    r = Benchmark.measure  {
      if artist_count > 0
        Artist.delete_all("views >= #{num}")
      else
        num.times do |i|
          Artist.connection.execute "INSERT INTO artists (name, views) VALUES ('artist#{i}', #{i});"
        end
      end
    }

    new_artist_count = Artist.count
    raise "#{num} expected but was #{new_artist_count}" unless new_artist_count == num

    friendly_num = new_artist_count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    puts "\n-------------------------------------"
    puts "Time to populate #{friendly_num} rows: #{r.real}s"
  end

  def clear_artists
    Artist.delete_all
  end

  def get_avg_time(size, meth)
    r = Benchmark.measure{
      TIMES_PER_TEST.times do
        Artist.send(meth, size)
      end
    }
    r.real / TIMES_PER_TEST.to_f
  end

  def print_results(size, avg, id_shuffle_avg)
    random_faster = ''
    shuffle_faster = ''

    if avg < id_shuffle_avg
      perc = ((1 - (avg / id_shuffle_avg)) * 100).round(2)
      random_faster = "(#{perc}% faster)"
    else
      perc = ((1 - (id_shuffle_avg / avg)) * 100).round(2)
      shuffle_faster = "(#{perc}% faster)"
    end

    puts "random(#{size}),               avg: #{avg}s  #{random_faster}"
    puts "random_by_id_shuffle(#{size}), avg: #{id_shuffle_avg}s  #{shuffle_faster}"
  end


  should 'do dem tests' do

    TESTS.each do |t|
      rows = t[:total_rows]
      request_sizes = t[:request_sizes]

      ensure_artists rows

      request_sizes.each do |size|
        avg = get_avg_time(size, :random)
        id_shuffle_avg = get_avg_time(size, :random_by_id_shuffle)
        print_results(size, avg, id_shuffle_avg)
      end
    end

  end

end