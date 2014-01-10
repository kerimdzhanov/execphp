require 'spec_helper'

module ExecPHP
  describe RemoteServer do
    let(:template) { Template.new('923eb2658336db16d8a55fb4e1877e97') }

    describe '#initialize' do

      context 'when access token is given' do
        it 'assigns a given :access_token' do
          template = Template.new('923eb2658336db16d8a55fb4e1877e97')
          expect(template.access_token).to eq('923eb2658336db16d8a55fb4e1877e97')
        end
      end

      context 'when access token is not given' do
        it 'generates a random :access_token' do
          expect(SecureRandom).to receive(:hex).and_return('851132200bfeaf6e0ff27f1be88413ca')
          expect(Template.new.access_token).to eq('851132200bfeaf6e0ff27f1be88413ca')
        end
      end

    end

    describe '#render' do
      let(:template) { Template.new('923eb2658336db16d8a55fb4e1877e97') }

      it 'puts $EXECPHP_ACCESS_TOKEN variable definition' do
        expect(template.render).to include <<-PHPSCRIPT
$EXECPHP_ACCESS_TOKEN = '923eb2658336db16d8a55fb4e1877e97';
        PHPSCRIPT
      end

      it 'puts `EXECPHP_VERSION` constant definition' do
        expect(template.render).to include <<-PHPSCRIPT
define('EXECPHP_VERSION', '#{ExecPHP::VERSION}');
        PHPSCRIPT
      end
    end

  end
end
