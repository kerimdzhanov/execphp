
module ExecPHP

  # PHP script batch
  class ScriptBatch

    # Constructor accepts a block for initialization.
    # @yield [batch] passes a self instance to the block
    # @yieldparam batch [ScriptBatch] reference to itself
    def initialize(&block)
      @buffer = ''
      block.call(self) if block_given?
    end

    # Include php file to a current batch.
    # @param filename [String] full path to a php file
    def include_file(filename)
      contents = File.read(filename)

      match = /<\?(?:php)?\s*/.match(contents)
      if match
        contents.slice!(0, match[0].size)
      else
        contents = "?>\n#{contents}"
      end

      @buffer << "#{contents.chomp}\n\n"
    end
    alias require_once include_file

    # Append a string of php code to a current batch.
    # @param script [String] a string of pure php code
    def append(script)
      @buffer << "#{script}\n"
    end
    alias << append

    # @return [String] batch php script
    def to_script
      @buffer
    end
  end

end
