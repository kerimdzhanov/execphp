require 'execphp/version'
require 'yaml'
require 'json'

module ExecPHP
  autoload :ServerSideAccessor, 'execphp/server_side_accessor'
  autoload :RemoteServer, 'execphp/remote_server'
  autoload :ScriptBatch, 'execphp/script_batch'
end
