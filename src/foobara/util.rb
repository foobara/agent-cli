module Foobara
  module Util
    module_function

    def pipe_writeline(io, line = "")
      pipe_io_operation(io) do
        io.puts line
        io.flush
      end
    end

    def pipe_write_with_flush(io, text = "")
      pipe_io_operation(io) do
        io.write text
        io.flush
      end
    end

    def pipe_readline(io)
      pipe_io_operation(io) do
        io.readline.strip
      end
    end

    def pipe_wait_readable(io, timeout = nil)
      pipe_io_operation(io) do
        io.wait_readable(timeout)
      end
    end

    def pipe_io_operation(_io)
      yield
    rescue EOFError
      # :nocov:
      nil
      # :nocov:
    rescue IOError => e
      # :nocov:
      message = e.message

      if message.include?("closed") && message.include?("stream")
        nil
      else
        raise
      end
      # :nocov:
    end

    def close(io)
      io.close
      nil
    rescue IOError
      # :nocov:
      nil
      # :nocov:
    end
  end
end
