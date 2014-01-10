require 'net/http'
require 'uri'

module ExecPHP

  # Represents a remote server accessor.
  class RemoteServer
    autoload :Benchmark, 'benchmark'

    # Timer output format
    # @see #ping
    TIMER_FORMAT = '%4.6f'

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

    # Send ping requests to a remote server.
    # @param count [Fixnum] requests number limit
    # @param verbose [boolean] puts verbose information to $stdout
    # @return [Float|false] an average number of seconds that the request takes
    #   or false if request was failed by some reason
    def ping(count: 1, verbose: false)
      batch = ScriptBatch.new do |batch|
        batch << 'echo "pong!";'
      end

      if verbose
        puts "=> #{@execphp_uri}"
      end

      timers = []
      count.times do |i|
        timer = Benchmark.realtime do
          begin
            push(batch) do |res|
              return false unless res.code == '200' && res.body == 'pong!'
            end
          rescue StandardError
            return false
          end
        end

        if verbose && count > 1
          puts "##{i + 1} #{TIMER_FORMAT % timer}"
        end

        timers << timer
      end

      average = timers.any? ? (timers.inject(:+).to_f / timers.size).round(6) : 0.0

      if verbose
        puts "~> #{TIMER_FORMAT % average}"
      end

      average
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
