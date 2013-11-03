require 'spec_helper'

module ExecPHP
  describe RemoteServer do
    let(:server) do
      RemoteServer.new(
        exec_uri:     'http://localhost/exec.php',
        access_token: '!@#$%^'
      )
    end

    describe '#initialize' do
      it 'parses and assigns a given :exec_uri' do
        expect(server.exec_uri).to be_a URI
        expect(server.exec_uri.to_s).to eq('http://localhost/exec.php')
      end

      it 'assigns given :access_token' do
        expect(server.access_token).to eq '!@#$%^'
      end
    end

    describe '#generate_exec_php_file' do
      let(:output_dir) { File.join(TEMP_DIR, 'execphp') }
      let(:output_filename) { File.join(output_dir, 'exec.php') }

      def generate!
        server.generate_exec_php_file(output_dir)
      end

      it 'creates `exec.php` file in a specified output dir' do
        expect(File).to receive(:open).with(output_filename)
        generate!
      end

      it 'puts $EXECPHP_ACCESS_TOKEN variable definition' do
        io_mock = double
        expect(io_mock).to receive(:write) do |script|
          expect(script).to include "$EXECPHP_ACCESS_TOKEN = '!@#$%^';\n"
        end

        expect(File).to(receive(:open)) { |f, &block| block.call(io_mock) }

        generate!
      end

      it 'puts `EXECPHP_VERSION` constant definition' do
        io_mock = double
        expect(io_mock).to receive(:write) do |script|
          expect(script).to include "define('EXECPHP_VERSION', '#{ExecPHP::VERSION}');\n"
        end

        expect(File).to(receive(:open)) { |f, &block| block.call(io_mock) }

        generate!
      end

      context 'when output file is already exists and :overwrite is not given' do
        before(:each) do
          expect(File).to receive(:exists?).and_return true
        end

        it 'returns false' do
          expect(generate!).to be_false
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
          with(body: hash_including('@' => '!@#$%^')).
            should have_been_requested
      end

      it 'sends batch script\'s @buffer' do
        server.push(batch)

        a_request(:post, 'http://localhost/exec.php').
          with(body: hash_including({'$' => "echo \"PHP Test!\";\n"})).
            should have_been_requested
      end
    end

    describe '#ping' do
      context 'when no arguments given' do

        it 'requests a remote server' do
          stub_request(:post, 'http://localhost/exec.php')

          server.ping

          a_request(:post, 'http://localhost/exec.php').
            should have_been_made
        end

        context 'when request is failed' do
          before(:each) do
            stub_request(:post, 'http://localhost/exec.php').to_raise StandardError
          end

          it 'returns false' do
            expect(server.ping).to be_false
          end
        end

        context 'when response status is not ok' do
          before(:each) do
            stub_request(:post, 'http://localhost/exec.php')
              .to_return status: [404, 'Not Found']
          end

          it 'returns false' do
            expect(server.ping).to be_false
          end
        end

        context 'when response body is not as expected' do
          before(:each) do
            stub_request(:post, 'http://localhost/exec.php')
              .to_return body: '<!DOCTYPE html>'
          end

          it 'returns false' do
            expect(server.ping).to be_false
          end
        end

        context 'when response is ok' do
          before(:each) do
            stub_request(:post, 'http://localhost/exec.php')
              .to_return body: 'pong!'
          end

          it 'returns a number of seconds that the request takes' do
            expect(server.ping).to be_a Float
          end
        end

      end

      context 'when given :count is greater than one' do

        it 'requests a remote server given number of times' do
          stub_request(:post, 'http://localhost/exec.php').
            to_return body: 'pong!'

          server.ping(count: 2)

          a_request(:post, 'http://localhost/exec.php').
            should have_been_made.times(2)
        end

        it 'returns an average request time' do
          stub_request(:post, 'http://localhost/exec.php').
            to_return body: 'pong!'

          expect(Benchmark).to receive(:realtime).
                                 exactly(3).times.
                                 and_return 1.0

          time = server.ping(count: 3)
          expect(time).to eq 1.0
        end

        context 'if first request is failed' do
          before(:each) do
            stub_request(:post, 'http://localhost/exec.php').to_raise StandardError
          end

          it 'returns false' do
            expect(server.ping(count: 3)).to be_false
          end

          it "doesn't send a second one" do
            server.ping(count: 3)

            a_request(:post, 'http://localhost/exec.php').
              should have_been_made.once
          end
        end

      end

      context 'when given :verbose => true' do

        it 'prints out remote server\'s `exec_uri` [=>]' do
          stub_request(:post, 'http://localhost/exec.php')
          output = capture(:stdout) { server.ping(verbose: true) }
          expect(output).to include "=> http://localhost/exec.php\n"
        end

        it 'prints each request timing [#n]' do
          stub_request(:post, 'http://localhost/exec.php').
            to_return(body: 'pong!')

          output = capture(:stdout) { server.ping(count: 2, verbose: true) }

          expect(output).to match /^#1 0\.[\d]{6}$/
          expect(output).to match /^#2 0\.[\d]{6}$/
        end

        it 'prints average request timing [~>]' do
          stub_request(:post, 'http://localhost/exec.php').
            to_return body: 'pong!'

          output = capture(:stdout) { server.ping(count: 3, verbose: true) }

          expect(output).to match /^~> 0\.[\d]{6}$/
        end

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