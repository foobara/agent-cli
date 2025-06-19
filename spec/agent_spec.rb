RSpec.describe Foobara::Agent do
  after { Foobara.reset_alls }

  before do
    Foobara::Persistence.default_crud_driver = Foobara::Persistence::CrudDrivers::InMemory.new
  end

  let(:agent) do
    params = { command_classes:, llm_model: }

    if agent_name
      params[:agent_name] = agent_name
    end

    described_class.new(**params)
  end
  let(:result) { outcome.result }
  let(:errors) { outcome.errors }
  let(:errors_hash) { outcome.errors_hash }
  let(:agent_name) { "CapybaraAgent" }
  let(:llm_model) { "claude-3-7-sonnet-20250219" }

  context "when there are some capybaras but one has a bad year of birth" do
    use_capybaras_domain

    before do
      Capybaras::CreateCapybara.run!(name: "Fumiko", year_of_birth: 2020)
      Capybaras::CreateCapybara.run!(name: "Barbara", year_of_birth: 19)
      Capybaras::CreateCapybara.run!(name: "Basil", year_of_birth: 2021)
    end

    let(:command_classes) { [Capybaras::FindAllCapybaras, Capybaras::UpdateCapybara] }
    let(:goal) { "There is a capybara with a bad year of birth. Can you find and fix the bad record? Thanks!" }

    describe "#run_cli" do
      let(:io_in_pipe) { IO.pipe }
      let(:io_out_pipe) { IO.pipe }
      let(:io_err_pipe) { IO.pipe }
      let(:io_in_reader) { io_in_pipe.first }
      let(:io_in_writer) { io_in_pipe.last }
      let(:io_out_reader) { io_out_pipe.first }
      let(:io_out_writer) { io_out_pipe.last }
      let(:io_err_reader) { io_err_pipe.first }
      let(:io_err_writer) { io_err_pipe.last }

      let(:io_in) { io_in_reader }
      let(:io_out) { io_out_writer }
      let(:io_err) { io_err_writer }

      let(:agent_thread) do
        Thread.new do
          agent.run_cli(io_in:, io_out:, io_err: $stderr)
        rescue
          sleep 1
          Foobara::Util.close(io_in_writer)
          Foobara::Util.close(io_out_writer)
          Foobara::Util.close(io_err_writer)
        end
      end
      let(:monitor_agent_thread) do
        Thread.new do
          loop do
            sleep 1

            if io_in_reader.closed?
              break
            end

            if [:killed, :error, :failure].include?(agent.state_machine.current_state)
              # Give time for error to be printed to stdout
              sleep 1
              Foobara::Util.close(io_in_writer)
              Foobara::Util.close(io_in_reader)
              Foobara::Util.close(io_out_reader)
              Foobara::Util.close(io_out_writer)
              break
            end
          end
        end
      end

      def next_message_to_user
        response = nil

        begin
          loop do
            ready = Foobara::Util.pipe_wait_readable(io_out_reader, 1)

            if [:killed, :error, :failure].include?(agent.state_machine.current_state)
              break
            end

            break if io_out_reader.closed?

            next unless ready

            response = Foobara::Util.pipe_readline(io_out_reader)
            break
          end
        rescue EOFError
          nil
        end

        if response =~ /\A[\s>]*\z/
          next_message_to_user
        else
          response
        end
      end

      before do
        monitor_agent_thread
        agent_thread
      end

      after do
        Foobara::Util.close(io_in_writer)
        Foobara::Util.close(io_out_writer)
        Foobara::Util.close(io_err_writer)
        Foobara::Util.close(io_in_reader)
        Foobara::Util.close(io_out_reader)
        Foobara::Util.close(io_err_reader)

        agent_thread.join
        monitor_agent_thread.join
      end

      it "can handle new goals with old context", vcr: { record: :none } do
        # consume the welcome message
        response = next_message_to_user
        expect(response).to be_a(String)

        Capybaras::Capybara.transaction do
          expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
        end

        io_in_writer.puts goal

        # eat up progress message
        response = next_message_to_user
        expect(response).to be_a(String)
        # the message to the user
        response = next_message_to_user
        expect(response).to be_a(String)

        Capybaras::Capybara.transaction do
          expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(2019)
        end

        io_in_writer.puts "Thank you so much! Can you set it back so that I can do the demo over again? Thanks!"

        # eat up progress message
        response = next_message_to_user
        expect(response).to be_a(String)
        # the message to the user
        response = next_message_to_user
        expect(response).to be_a(String)

        Capybaras::Capybara.transaction do
          expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
        end
      end

      context "with no name" do
        let(:agent_name) { nil }

        it "can handle new goals with old context", vcr: { record: :none } do
          # consume the welcome message
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          end

          io_in_writer.puts goal

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(2019)
          end

          io_in_writer.puts "Thank you so much! Can you set it back so that I can do the demo over again? Thanks!"

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          end

          io_in_writer.puts "Thank you so much! Can you set it back so that I can do the demo over again? Thanks!"

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          io_in_writer.puts "/quit"
        end
      end

      context "when using openai" do
        let(:llm_model) { "chatgpt-4o-latest" }

        it "can handle new goals with old context using openai models", vcr: { record: :none } do
          # consume the opening prompt
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          end

          io_in_writer.puts goal

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(2019)
          end

          io_in_writer.puts "Thank you so much! Can you set it back so that I can do the demo over again? Thanks!"

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          end
        end
      end

      context "when using ollama" do
        let(:llm_model) { "deepseek-r1:32b" }

        let(:goal) do
          "There is a capybara with a bad year of birth. " \
            "It was accidentally entered as a 2-digit year instead of a 4-digit year. " \
            "I want you to find and fix the bad record by adding the missing first two digits which are 2 and 0."
        end

        it "can handle new goals with old context using ollama models", vcr: { record: :none } do
          response = next_message_to_user
          expect(response).to include "Welcome"

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          end

          Foobara::Util.pipe_writeline(io_in_writer, goal)

          # eat up progress message
          response = next_message_to_user
          expect(response).to be_a(String)
          # the message to the user
          response = next_message_to_user
          expect(response).to be_a(String)

          Capybaras::Capybara.transaction do
            expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(2019)
          end

          # deepseek-r1 does not seem to do a consistently good job of setting it back to 19 so commenting this
          # out for now.
          #
          # Foobara::Util.pipe_writeline(
          #   io_in_writer,
          #   "Can you change Barbara's year_of_birth back to 19 so I can do the demo over again?"
          # )
          #
          # # eat up progress message
          # response = next_message_to_user
          # expect(response).to be_a(String)
          # # the message to the user
          # response = next_message_to_user
          # expect(response).to be_a(String)
          #
          # Capybaras::Capybara.transaction do
          #   expect(Capybaras::Capybara.find_by(name: "Barbara").year_of_birth).to eq(19)
          # end
        end
      end
    end
  end
end
