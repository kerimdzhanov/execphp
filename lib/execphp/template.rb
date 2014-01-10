require 'erb'
require 'securerandom'

module ExecPHP

  # Create an instance to render an `exec.php` file for uploading to a remote server.
  class Template

    attr_reader :access_token

    # @param access_token [String] remote server access token
    def initialize(access_token = SecureRandom.hex)
      @access_token = access_token
    end

  end

  tpl_filename = File.join(__dir__, 'exec.php.erb')
  ERB.new(File.read(tpl_filename)).def_method(Template, 'render')

end
