require 'rspec'
require 'rspec/core/formatters/json_formatter'

# TestBuddy
class TestBuddy
  def initialize
    @initial_run = true
    @failing_tests = ['.']
  end

  def execute_input(input)
    case input
    when 'test'
      run_tests
    when 'status'
      display_status
    else
      puts 'unrecognized input, try again'
    end
  end

  # https://stackoverflow.com/questions/52597371/execute-an-rspec-test-in-rails-console
  def run_tests
    failed_tests_during_run = []

    error_stream = StringIO.new
    output_stream = StringIO.new

    RSpec::Core::Runner.run(
      @failing_tests + ['--format=json'],
      error_stream,
      output_stream
    )

    RSpec.reset

    errors =
      (JSON.parse(error_stream.string) unless error_stream.string.empty?)

    results =
      (JSON.parse(output_stream.string) unless output_stream.string.empty?)

    puts 'Finished executing tests.'
    puts results['summary_line']
    puts ''

    i = 1
    results['examples'].each do |ex|
      next if ex['status'] == 'passed'

      path = "#{ex['file_path']}:#{ex['line_number']}"
      puts "Failed test #{i}: #{path}"
      puts ex['full_description']
      puts ex['exception']['message'] if ex['exception']
      puts ''

      failed_tests_during_run.append(path)
      i += 1
    end

    @failing_tests = failed_tests_during_run
    @initial_run = false
  end

  def display_status
    if @initial_run
      puts 'no initial test execution...'
      return
    end

    if @failing_tests.size.zero?
      puts 'All tests passed!'
    else
      puts "#{@failing_tests.size} failures"
    end
  end

  def execute
    loop do
      print '> '
      a = gets.chomp
      execute_input a
    rescue StandardError => e
      puts "[EXIT] failure: #{e}"
      return
    end
  end
end

TestBuddy.new.execute
