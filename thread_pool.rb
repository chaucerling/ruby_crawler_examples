require 'thread'

class Pool
  def initialize(size)
    @size = size
    @queue = Queue.new
    @running = false
    @threads = @size.times.map do |i|
      Thread.new do
        Thread.current[:id] = i
        # loop processing jobs until catch exit
        catch (:exit) do
          loop do
            args, block = @queue.pop
            block.call(*args)
          end
        end
        puts "Thread: #{Thread.current[:id]} exit\n"
      end
    end
  end

  # add schedule jobs
  def schedule(*args, &block)
    @queue << [args, block]
  end

  # join all threads and exit them
  def shutdown
    @size.times do
      schedule { throw :exit }
    end
    @threads.each(&:join)
    @running = false
    puts "finished all"
  end
end

t_start = Time.now
pool = Pool.new(10)

10.times do |i|
  pool.schedule(i+2) do |num|
    sleep rand(2)
    puts "Job #{num} finished by thread #{Thread.current[:id]}, Time:#{Time.now - t_start}\n"
  end
end

puts "add task 1, Time:#{Time.now - t_start}\n"

sleep 2

10.times do |i|
  pool.schedule(i+2) do |num|
    puts "Job #{num} finished, Time:#{Time.now - t_start}\n"
  end
end

puts "add task 2, Time:#{Time.now - t_start}\n"

pool.shutdown

at_exit { puts "exit, Time:#{Time.now - t_start}\n" }
