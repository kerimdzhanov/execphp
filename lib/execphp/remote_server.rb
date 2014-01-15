require 'net/http'
require 'uri'

module ExecPHP

  # Represents a remote server accessor.
  class RemoteServer
    # @return [URI] path to a remote server's "/exec.php" script
    attr_reader :execphp_uri

    # @return [String] remote server access token
    attr_reader :access_token

    # Initialize a remote server accessor instance.
    # @param execphp_url [String] path to a remote server's "/exec.php" script
    # @param access_token [String] remote server access token
    def initialize(execphp_url, access_token)
      @execphp_uri  = URI(execphp_url)
      @access_token = access_token
    end

    def save_as(filename)
      format = File.extname(filename)[1, 4]

      config = {
        'execphp_url' => @execphp_uri.to_s,
        'access_token' => @access_token
      }

      File.write(filename, case format
        when 'yaml'
          YAML.dump(config)
        when 'json'
          JSON.pretty_generate(config)
        else
          raise "Unrecognized config file format (#{format})"
      end)
    end

    def self.from_file(filename)
      format = File.extname(filename)[1, 4]

      config = case format
        when 'yaml'
          YAML.load_file(filename)
        when 'json'
          JSON.load(File.read filename)
        else
          raise "Unrecognized config file format (#{format})"
      end

      new(config['execphp_url'], config['access_token'])
    end

    # Push a given script batch to a remote server for execution.
    # @param batch [ScriptBatch] script batch to execute
    # @param block [Proc] optional callback
    def push(batch, &block)
      @http ||= Net::HTTP.new(@execphp_uri.host, @execphp_uri.port)
      @request ||= Net::HTTP::Post.new(@execphp_uri.request_uri)

      @request.set_form_data('@' => @access_token,
                             '$' => batch.to_script)

      response = @http.request(@request)

      if block_given?
        block.call(response)
      else
        response
      end
    end

    # Request a remote server's `exec.php` version.
    # @return [String] version number definition or nil if request was failed
    def remote_version
      batch = ScriptBatch.new do |batch|
        batch << 'echo EXECPHP_VERSION;'
      end

      begin
        version = push(batch).body
        return version if version =~ /^\d\.\d\.\d$/
      rescue StandardError
        nil
      end
    end
  end

end
