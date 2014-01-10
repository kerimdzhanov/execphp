require 'securerandom'
require 'erb'

module ExecPHP

  # Server-side accessor script file generator.
  class ServerSideAccessor

    # @return [String] remote server access token
    attr_reader :access_token

    # @param access_token [String] remote server access token
    def initialize(access_token = SecureRandom.hex)
      @access_token = access_token
    end

    # @param filename [String] output filename
    def generate(filename)
      File.write(filename, render)
    end

  end

  ERB.new(File.read(File.join(__dir__, 'exec.php.erb')))
    .def_method(ServerSideAccessor, 'render', 'execphp/exec.php.erb')

end
