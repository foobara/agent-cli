require "io/wait"

module Foobara
  class Agent
    def run_cli(io_in: $stdin, io_out: $stdout, io_err: $stderr)
      CliRunner.new(self, io_in:, io_out:, io_err:).run
    end
  end
end
