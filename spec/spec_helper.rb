$0 = 'execphp'
ARGV.clear

require 'execphp'
require 'webmock/rspec'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
end

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
