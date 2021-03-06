require_relative '../../../lib/bookbinder/configuration_fetcher'

module Bookbinder
  describe ConfigurationFetcher do
    let(:path_to_config_file) { './config.yml' }
    let(:config_validator)    { double('validator') }
    let(:logger)              { double('logger') }
    let(:loader)              { double('loader') }
    let(:config_fetcher)      { ConfigurationFetcher.new(logger, config_validator, loader) }

    it 'can read config from a relative path even when I have changed working directory' do
      config_fetcher.set_config_file_path(path_to_config_file)
      allow(config_validator).to receive(:valid?).and_return nil
      allow(loader).to receive(:load).with(File.expand_path(path_to_config_file)) { { foo: 'bar' } }
      Dir.chdir('/tmp') do |tmp|
        expect(config_fetcher.fetch_config).to eq(Configuration.new(logger, {foo: 'bar'}))
      end
    end

    context 'when file path has been set' do
      before do
        config_fetcher.set_config_file_path(path_to_config_file)
        allow(config_validator).to receive(:valid?) { nil }
      end

      it 'reads a configuration object from the configuration file' do
        section1 = {
          'repository' => {
            'name' => 'foo/dogs-repo'
          },
          'directory' => 'concepts'
        }
        expected_config_hash = {
          'sections' => [section1],
          'public_host' => 'http://example.com',
        }
        config_hash_in_file = {
          'sections' => [section1],
          'public_host' => 'http://example.com',
        }
        allow(loader).to receive(:load).with(File.expand_path(path_to_config_file)) { config_hash_in_file }
        expect(config_fetcher.fetch_config).to eq(Configuration.new(logger, expected_config_hash))
      end

      it 'caches configuration loads' do
        expect(loader).to receive(:load) { {} }
        config_fetcher.fetch_config

        expect(loader).not_to receive(:load)
        config_fetcher.fetch_config
      end

      context 'when the configuration file does not exist' do
        it 'raises an informative error' do
          allow(loader).to receive(:load) { raise FileNotFoundError, 'YAML' }
          expect { config_fetcher.fetch_config }.to raise_error /The configuration file specified does not exist. Please create a config YAML file/
        end
      end

      context 'when the configuration file has invalid syntax' do
        it 'raises an informative error' do
          allow(loader).to receive(:load) { raise InvalidSyntaxError }
          expect { config_fetcher.fetch_config }.to raise_error /There is a syntax error in your config file/
        end
      end
    end

    context 'when the config is empty' do
      it 'raises' do
        allow(loader).to receive(:load).and_return nil
        expect { config_fetcher.fetch_config }.
            to raise_error /Your config.yml appears to be empty./
      end
    end

    context 'when the config is invalid' do
      it 'raises the error it receives' do
        error = RuntimeError.new
        allow(loader).to receive(:load) { {} }
        allow(config_validator).to receive(:valid?).and_return(error)
        expect { config_fetcher.fetch_config }.to raise_error(error)
      end
    end
  end
end
