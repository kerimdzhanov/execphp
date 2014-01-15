require 'spec_helper'

module ExecPHP
  describe RemoteServer do
    let(:server) do
      RemoteServer.new('http://localhost/exec.php', '851132200bfeaf6e0ff27f1be88413ca')
    end

    describe '#initialize' do
      it 'parses and assigns a given :exec_uri' do
        expect(server.execphp_uri).to be_a URI
        expect(server.execphp_uri.to_s).to eq 'http://localhost/exec.php'
      end

      it 'assigns given :access_token' do
        expect(server.access_token).to eq '851132200bfeaf6e0ff27f1be88413ca'
      end
    end

    describe '#save_as' do
      context 'when filename extension is .yaml' do
        let(:filename) { '/path/to/config.yaml' }

        it 'saves config as yaml' do
          expect(File).to receive(:write)
              .with('/path/to/config.yaml', <<-YAML)
---
execphp_url: http://localhost/exec.php
access_token: 851132200bfeaf6e0ff27f1be88413ca
          YAML

          server.save_as(filename)
        end
      end

      context 'when filename extension is .json' do
        let(:filename) { '/path/to/config.json' }

        it 'saves config as json' do
          expect(File).to receive(:write)
              .with('/path/to/config.json', <<-JSON.chomp)
{
  "execphp_url": "http://localhost/exec.php",
  "access_token": "851132200bfeaf6e0ff27f1be88413ca"
}
          JSON

          server.save_as(filename)
        end
      end

      context 'when filename extension is unknown' do
        let(:filename) { '/path/to/config.jpeg' }

        it 'raises an error' do
          expect {
            server.save_as(filename)
          }.to raise_error RuntimeError, 'Unrecognized config file format (jpeg)'
        end
      end
    end

    describe '.from_file', focus: true do
      context 'when filename extension is .yaml' do
        let(:filename) { File.join(__dir__, '../fixtures/remote-server.yaml') }

        it 'loads a yaml config' do
          server = RemoteServer.from_file(filename)
          expect(server.execphp_uri).to eq URI('http://localhost/exec.php')
          expect(server.access_token).to eq '851132200bfeaf6e0ff27f1be88413ca'
        end
      end

      context 'when filename extension is .json' do
        let(:filename) { File.join(__dir__, '../fixtures/remote-server.json') }

        it 'loads a json config' do
          server = RemoteServer.from_file(filename)
          expect(server.execphp_uri).to eq URI('http://localhost/exec.php')
          expect(server.access_token).to eq '851132200bfeaf6e0ff27f1be88413ca'
        end
      end
    end

    describe '#push' do
      let(:batch) do
        ScriptBatch.new do |batch|
          batch << 'echo "PHP Test!";'
        end
      end

      before(:each) { stub_request(:post, 'http://localhost/exec.php') }

      it 'pushes a given script batch to a specified :exec_uri' do
        server.push(batch)

        a_request(:post, 'http://localhost/exec.php').
          should have_been_requested
      end

      it 'sends remote server\'s @access_token' do
        server.push(batch)

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including('@' => '851132200bfeaf6e0ff27f1be88413ca')).
            should have_been_requested
      end

      it 'sends batch script\'s @buffer' do
        server.push(batch)

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including({'$' => "echo \"PHP Test!\";\n"})).
            should have_been_requested
      end
    end

    describe '#remote_version' do
      it 'sends the `echo EXECPHP_VERSION;` script batch' do
        stub_request(:post, 'http://localhost/exec.php')

        server.remote_version

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including('$' => "echo EXECPHP_VERSION;\n")).
            should have_been_requested
      end

      context 'when request is failed' do
        before(:each) do
          stub_request(:post, 'http://localhost/exec.php').to_raise StandardError
        end

        it 'returns nil' do
          expect(server.remote_version).to be_nil
        end
      end

      context 'when response status is not ok' do
        before(:each) do
          stub_request(:post, 'http://localhost/exec.php')
            .to_return status: [404, 'Not Found']
        end

        it 'returns nil' do
          expect(server.remote_version).to be_nil
        end
      end

      context 'when response body is not as expected' do
        before(:each) do
          stub_request(:post, 'http://localhost/exec.php')
            .to_return body: '<!DOCTYPE html>'
        end

        it 'returns nil' do
          expect(server.remote_version).to be_nil
        end
      end

      context 'when response is ok' do
        before(:each) do
          stub_request(:post, 'http://localhost/exec.php')
            .to_return body: '1.2.3'
        end

        it 'returns version number definition' do
          expect(server.remote_version).to eq '1.2.3'
        end
      end
    end

  end
end
