require 'spec_helper'

module ExecPHP
  describe RemoteServer do
    let(:remote_server) do
      RemoteServer.new('http://localhost/exec.php', 'super-secret')
    end

    describe '#initialize' do
      it 'parses and assigns a given :exec_uri' do
        execphp_uri = remote_server.execphp_uri
        expect(execphp_uri).to be_a URI
        expect(execphp_uri.to_s).to eq 'http://localhost/exec.php'
      end

      it 'assigns a given :access_token' do
        expect(remote_server.access_token).to eq 'super-secret'
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
access_token: super-secret
          YAML

          remote_server.save_as(filename)
        end
      end

      context 'when filename extension is .json' do
        let(:filename) { '/path/to/config.json' }

        it 'saves config as json' do
          expect(File).to receive(:write)
              .with('/path/to/config.json', <<-JSON.chomp)
{
  "execphp_url": "http://localhost/exec.php",
  "access_token": "super-secret"
}
          JSON

          remote_server.save_as(filename)
        end
      end

      context 'when filename extension is unknown' do
        let(:filename) { '/path/to/config.cfg' }

        it 'raises an error' do
          expect {
            remote_server.save_as(filename)
          }.to raise_error RuntimeError, 'Unrecognized config file format (.cfg)'
        end
      end
    end

    describe '.from_file' do
      context 'when filename extension is .yaml' do
        let(:filename) { File.join(__dir__, '../fixtures/remote-server.yaml') }

        it 'loads a yaml config' do
          remote_server = RemoteServer.from_file(filename)
          expect(remote_server.execphp_uri).to eq URI('http://localhost/exec.php')
          expect(remote_server.access_token).to eq '%$#@!'
        end
      end

      context 'when filename extension is .json' do
        let(:filename) { File.join(__dir__, '../fixtures/remote-server.json') }

        it 'loads a json config' do
          remote_server = RemoteServer.from_file(filename)
          expect(remote_server.execphp_uri).to eq URI('http://localhost/exec.php')
          expect(remote_server.access_token).to eq '!%@$#'
        end
      end
    end

    describe '#exec' do
      let(:batch) do
        ScriptBatch.new { |s| s << 'echo "PHP Test!";' }
      end

      before(:each) do
        stub_request(:post, 'http://localhost/exec.php')
          .to_return(body: 'PHP Test!')
      end

      it 'pushes a given script batch to a specified :exec_uri' do
        remote_server.exec(batch)

        a_request(:post, 'http://localhost/exec.php').
          should have_been_requested
      end

      it 'sends remote server\'s @access_token' do
        remote_server.exec(batch)

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including('@' => 'super-secret')).
            should have_been_requested
      end

      it 'sends batch script\'s @buffer' do
        remote_server.exec(batch)

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including({'$' => "echo \"PHP Test!\";\n"})).
            should have_been_requested
      end

      it 'returns an http response' do
        res = remote_server.exec(batch)
        expect(res).to be_a Net::HTTPOK
        expect(res.body).to eq 'PHP Test!'
      end

      context 'when block given' do
        it 'yields it passing a `response` with readable body' do
          remote_server.exec(batch) do |res|
            expect(res).to be_a Net::HTTPOK

            body = ''

            res.read_body do |segment|
              body << segment
            end

            expect(body).to eq 'PHP Test!'
          end
        end
      end
    end

    describe '#version' do
      let(:response) { Hash.new }

      before(:each) do
        stub_request(:post, 'http://localhost/exec.php').to_return(response)
      end

      subject { remote_server.version }

      it 'sends the "echo EXECPHP_VERSION;" script' do
        subject # perform the request

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including('$' => "echo EXECPHP_VERSION;\n")).
            should have_been_requested
      end

      context 'when response status is not ok' do
        let(:response) { {status: [404, 'Not Found']} }
        it { should be_nil }
      end

      ['', '12345', '<!DOCTYPE html>...'].each do |body|
        context 'when response body is unexpected' do
          let(:response) { {body: body} }
          it { should be_nil }
        end
      end

      %w[1.2.3 0.1.0.pre 1.0.0.rc1 1.2.3.beta].each do |body|
        context "when response body is '#{body}'" do
          let(:response) { {body: body} }
          it { should eq body }
        end
      end

    end

  end
end
