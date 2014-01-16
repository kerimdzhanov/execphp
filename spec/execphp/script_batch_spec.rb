require 'spec_helper'

module ExecPHP

  describe ScriptBatch do
    let(:batch) { ScriptBatch.new }

    describe '#initialize' do
      let(:probe) { lambda { |o| } }

      it 'accepts an initialization block' do
        expect(probe).to receive(:call)
        ScriptBatch.new(&probe)
      end

      it 'passes itself to an initialization block' do
        ScriptBatch.new do |batch|
          expect(batch).to be_a ScriptBatch
        end
      end
    end

    describe '#include_file' do
      def fixture(filename)
        File.join(FIXTURES_DIR, filename)
      end

      it 'appends a given file contents to a current batch\'s @buffer' do
        batch.include_file(fixture 'function_hello.php')
        batch.include_file(fixture 'function_goodbye.php')
        batch.include_file(fixture 'functions_call.php')
        batch.include_file(fixture 'functions_call.php')

        expect(batch.to_s).to eq <<-PHPSCRIPT
function say_hello() {
  echo "Hello PHP!";
}

function say_goodbye() {
  echo "Goodbye PHP!";
}

say_hello();
say_goodbye();

say_hello();
say_goodbye();
        PHPSCRIPT
      end
    end

    describe '#append' do
      it 'appends a given code string to a current batch\'s @buffer' do
        batch << 'echo "Hello PHP";'
        batch << 'echo "Goodbye PHP";'
        expect(batch.to_s).to eq <<-PHPSCRIPT
echo "Hello PHP";

echo "Goodbye PHP";
        PHPSCRIPT
      end
    end

  end

end
