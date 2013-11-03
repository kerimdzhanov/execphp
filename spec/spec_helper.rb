$0 = 'execphp'
ARGV.clear

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

require 'execphp'
require 'webmock/rspec'

TEMP_DIR = (File.symlink?('/tmp') ? "/#{File.readlink('/tmp')}" : '/tmp')

RSpec.configure do |config|
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
end
