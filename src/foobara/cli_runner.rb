module Foobara
  class Agent < CommandConnector
    class CliRunner
      attr_accessor :io_in, :io_out, :io_err, :agent

      def initialize(agent, io_in: $stdin, io_out: $stdout, io_err: $stderr)
        self.agent = agent
        self.io_in = io_in
        self.io_out = io_out
        self.io_err = io_err
      end

      def run
        print_welcome_message
        print_prompt

        loop do
          ready = Util.pipe_wait_readable(io_in, 1)

          break if agent.killed?
          break if io_in.closed?

          next unless ready

          line = Util.pipe_readline(io_in)

          break if line.nil? || io_in.closed? || agent.killed?

          goal = line.strip

          if goal =~ /\A\/?(exit|quit|bye)\z/i
            print_agent_message("Goodbye for now!")
            agent.kill!
            break
          end

          next if goal.empty?

          begin
            print_agent_message("On it...")
            outcome = agent.accomplish_goal(goal)
            print_outcome(outcome)
            print_prompt
          rescue => e
            # :nocov:
            Util.pipe_writeline(io_err, e.message)
            Util.pipe_writeline(io_err, e.backtrace)
            # :nocov:
          end
        end
      end

      def print_welcome_message
        welcome_message = if agent_name
                            "Welcome! I am #{agent_name}!"
                          else
                            "Welcome to the Foobara Agent CLI!"
                          end

        welcome_message << " What would you like me to attempt to accomplish?"

        Util.pipe_writeline(io_out, "\n#{welcome_message}\n")
      end

      def print_prompt
        Util.pipe_write_with_flush(io_out, "\n> ")
      end

      def print_outcome(outcome)
        message, stream = if outcome.success?
                            [outcome.result[:message_to_user], io_out]
                          else
                            # :nocov:
                            ["ERROR: #{outcome.errors_hash}", io_err]
                            # :nocov:
                          end

        print_agent_message(message, stream)
      end

      def print_agent_message(message, stream = io_out)
        name = agent_name || "Agent"
        Util.pipe_writeline(stream, "\n#{name} says: #{message}\n")
      end

      def agent_name
        name = agent.agent_name

        if name && !name.empty?
          name
        end
      end
    end
  end
end
