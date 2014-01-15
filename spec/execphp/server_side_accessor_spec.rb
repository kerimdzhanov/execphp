require 'spec_helper'

module ExecPHP
  describe ServerSideAccessor do

    describe '#initialize' do

      context 'when access token is given' do
        let(:accessor) { ServerSideAccessor.new('923eb2658336db16d8a55fb4e1877e97') }

        it 'assigns a given :access_token' do
          expect(accessor.access_token).to eq '923eb2658336db16d8a55fb4e1877e97'
        end
      end

      context 'when access token is not given' do
        let(:accessor) { ServerSideAccessor.new }

        it 'generates a random :access_token' do
          expect(SecureRandom).to receive(:hex).and_return('851132200bfeaf6e0ff27f1be88413ca')
          expect(accessor.access_token).to eq '851132200bfeaf6e0ff27f1be88413ca'
        end
      end

    end

    describe '#render' do
      let(:accessor) { ServerSideAccessor.new('923eb2658336db16d8a55fb4e1877e97') }

      it 'puts :access_token value' do
        expect(accessor.render).to include "'923eb2658336db16d8a55fb4e1877e97'"
      end

      it 'puts `EXECPHP_VERSION` constant definition' do
        expect(accessor.render).to include <<-PHPSCRIPT
define('EXECPHP_VERSION', '#{ExecPHP::VERSION}');
        PHPSCRIPT
      end
    end

    describe '#generate' do
      let(:accessor) { ServerSideAccessor.new('851132200bfeaf6e0ff27f1be88413ca') }

      before(:each) do
        allow(accessor).to receive(:render).and_return("<?php\n")
      end

      it 'generates a script file with a given filename' do
        expect(File).to receive(:write).with('/path/to/exec.php', "<?php\n")
        accessor.generate('/path/to/exec.php')
      end
    end

  end
end
