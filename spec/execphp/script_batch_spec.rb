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
      it 'appends a given file contents to a current batch\'s @buffer' do
        filename = File.join(__dir__, '../fixtures/hello_function.php')
        batch.require_once filename
        expect(batch.to_script).to eq <<-EOT
function say_hello() {
  echo "Hello Yay!";
}\n
        EOT
      end
    end

    describe '#append' do
      it 'appends a given code string to a current batch\'s @buffer' do
        batch << 'echo "php-5.4.25";'
        batch << 'echo "php-5.4.26";'
        expect(batch.to_script).to eq %Q[echo "php-5.4.25";\necho "php-5.4.26";\n]
      end
    end

  end

end
