module Foobara
  class Agent
    class CliRunner
      attr_accessor :io_in, :io_out, :io_err, :agent

      def initialize(agent, io_in: $stdin, io_out: $stdout, io_err: $stderr)
        self.agent = agent
        self.io_in = io_in
        self.io_out = io_out
        self.io_err = io_err
      end

      def run
        Util.pipe_write_with_flush(
          io_out,
          "\nWelcome to the Foobara Agent CLI! Type your goal and press enter to get started.\n\n> "
        )

        loop do
          ready = Util.pipe_wait_readable(io_in, 1)

          break if agent.killed?
          break if io_in.closed?

          next unless ready

          line = Util.pipe_readline(io_in)

          break if line.nil? || io_in.closed? || agent.killed?

          goal = line.strip

          break if goal =~ /\A(exit|quit|bye)\z/i
          next if goal.empty?

          begin
            outcome = agent.accomplish_goal(goal)

            if outcome.success?
              result = outcome.result
              Util.pipe_writeline(io_out, "\nAgent says: #{result[:message_to_user]}\n")
            else
              # :nocov:
              Util.pipe_writeline(io_err, "\nError: #{outcome.errors_hash}\n")
              # :nocov:
            end

            Util.pipe_write_with_flush(io_out, "\n> ")
          rescue => e
            # :nocov:
            Util.pipe_writeline(io_err, e.message)
            Util.pipe_writeline(io_err, e.backtrace)
            # :nocov:
          end
        end
      end
    end
  end
end
