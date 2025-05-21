require "io/wait"

module Foobara
  class Agent
    def run_cli(io_in: $stdin, io_out: $stdout, io_err: $stderr)
      io_out.write "> "
      io_out.flush

      loop do
        input_is_available = io_in.wait_readable(1)

        if input_is_available
          line = io_in.gets
          if line.nil?
            break
          end

          goal = line.chomp

          begin
            outcome = accomplish_goal(goal)

            if outcome.success?
              result = outcome.result
              io_out.puts
              io_out.puts result[:message_to_user]
              io_out.puts
              io_out.flush
            else
              # :nocov:
              io_out.puts
              io_err.puts outcome.errors_hash
              io_err.puts
              io_err.flush
              # :nocov:
            end

            io_out.write "> "
            io_out.flush
          rescue => e
            # :nocov:
            io_out.puts e.message
            io_err.puts e.message
            io_err.puts e.backtrace
            io_err.flush
            # :nocov:
          end
        end
      end
    end
  end
end
