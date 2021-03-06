require_relative '../../../lib/bookbinder/configuration'
require_relative '../../helpers/nil_logger'

module Bookbinder
  describe Configuration do
    let(:bookbinder_schema_version) { '1.0.0' }
    let(:logger) { NilLogger.new }
    let(:user_schema_version) { '1.0.0' }
    let(:archive_menu) { [] }
    let(:config_hash) do
      {
          'book_repo' => 'some-org/some-repo',
          'versions' => %w(v1.7.1.9 redacted v3),
          'cred_repo' => 'some-org/cred-repo',
          'layout_repo' => 'some-org/some-repo',
          'sections' => ['section1', 'section2'],
          'public_host' => 'http://www.example.com',
          'template_variables' => {'some-var' => 'some-value'},
          'schema_version' => user_schema_version,
          'archive_menu' => archive_menu
      }
    end

    let(:config) { Configuration.new(logger, config_hash) }

    describe 'accessing configuration values' do
      it 'exposes some of these keys' do
        config_hash.delete('schema_version')
        config_hash.each do |key, value|
          expect(config.public_send(key)).to eq value
        end
      end

      context 'when optional keys do not exist' do
        it 'returns nil' do
          config_hash.delete('archive_menu')
          expect(config.public_send('archive_menu')).to be_nil
        end
      end

      it 'returns an empty hash when template_variables is not provided' do
        config_hash.delete('template_variables')
        expect(config.template_variables).to eq({})
      end
    end

    describe 'credentials' do
      let(:aws_hash) { {'access_key' => 'some-secret', 'secret_key' => 'wow-agent', 'green_builds_bucket' => 'its_a_pail'} }
      let(:cf_staging_routes) {{ 'some-staging-domain.io' => ['some-staging-host'] }}
      let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host'] }}
      let(:cf_hash) do
        {
            'api_endpoint' => 'http://some-api-endpoint.example.com',
            'staging_host' => cf_staging_routes,
            'production_space' => 'some-prod-space',
            'production_host' => cf_prod_routes,
            'staging_space' => 'some-staging-space',
            'app_name' => 'some-app',
            'username' => 'some-user',
            'password' => 'some-pass',
            'organization' => 'some-org'
        }
      end
      let(:creds_hash) { {'aws' => aws_hash, 'cloud_foundry' => cf_hash} }
      let(:cred_repo) { double(credentials: creds_hash) }

      before do
        repository = double
        allow(GitHubRepository).to receive(:new).with(logger: logger, full_name: 'some-org/cred-repo', git_accessor: Git).and_return(repository)
        allow(RemoteYamlCredentialProvider).to receive(:new).with(logger, repository).and_return(cred_repo)
      end

      describe '#aws_credentials' do
        it 'returns a Configuration with the AWS credentials from the credentials repository' do
          expect(config.aws_credentials.access_key).to eq('some-secret')
          expect(config.aws_credentials.secret_key).to eq('wow-agent')
          expect(config.aws_credentials.green_builds_bucket).to eq('its_a_pail')
        end

        it 'memoizes' do
          expect(config.aws_credentials).to equal(config.aws_credentials)
        end
      end

      describe Configuration::CfCredentials do
        let(:environment) { 'staging' }
        let(:cf_credentials) { Configuration::CfCredentials.new(cf_hash, environment) }

        it 'returns a Configuration with the CF credentials from the credentials repository' do
          expect(cf_credentials.api_endpoint).to eq('http://some-api-endpoint.example.com')
          expect(cf_credentials.app_name).to eq('some-app')
          expect(cf_credentials.username).to eq('some-user')
          expect(cf_credentials.password).to eq('some-pass')
          expect(cf_credentials.organization).to eq('some-org')
        end

        it 'memoizes' do
          expect(cf_credentials).to be(cf_credentials)
        end

        describe 'default values' do
          it 'defaults username to nil' do
            cf_hash.delete('username')
            expect(cf_credentials.username).to be_nil
          end

          it 'defaults password to nil' do
            cf_hash.delete('password')
            expect(cf_credentials.password).to be_nil
          end
        end

        describe 'environment' do
          context 'when production' do
            let(:environment) { 'production' }

            it 'uses production values for host and space' do
              expect(cf_credentials.routes).to eq('some-prod-domain.io'=>['some-prod-host'])
              expect(cf_credentials.space).to eq('some-prod-space')
            end
          end

          context 'when staging' do
            let(:environment) { 'staging' }

            it 'uses staging values for host and space' do
              expect(cf_credentials.routes).to eq('some-staging-domain.io'=>['some-staging-host'])
              expect(cf_credentials.space).to eq('some-staging-space')
            end
          end
        end

        describe '#routes' do
          let(:environment) { 'production' }

          context 'with a correctly formatted domain' do
            let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host'] }}
            it 'succeeds' do
              expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host'])
            end
          end

          context 'with multiple correctly formatted domains' do
            let(:cf_prod_routes) do
              {
                  'some-prod-domain.io' => ['some-prod-host'],
                  'another-prod-domain.io' => ['another-prod-host, yet-a-third-prod-host']
              }
            end
            it 'succeeds' do
              expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host'],
                                                  'another-prod-domain.io' => ['another-prod-host, yet-a-third-prod-host'])
            end
          end

          context 'when domains are incorrectly formatted' do
            context 'and domains are given as an array' do
              let(:cf_prod_routes) {{ ['some-prod-domain.io', 'another-prod-domain.io'] => ['some-prod-host'] }}
              it 'raises' do
                expect { cf_credentials.routes }.to raise_error(/Each domain in credentials must be a single string./)
              end
            end

            context 'and a domain is given without an extension' do
              let(:cf_prod_routes) {{ 'some-prod-domain' => ['some-prod-host'] }}
              it 'raises' do
                expect { cf_credentials.routes }.to raise_error(/must contain a web extension/)
              end
            end
          end

          context 'with correctly formatted routes' do
            let(:cf_prod_routes) {{ 'some-prod-domain.io' => ['some-prod-host', 'another-prod-host'] }}

            it 'succeeds' do
              expect(cf_credentials.routes).to eq('some-prod-domain.io' => ['some-prod-host', 'another-prod-host'])
            end
          end

          context 'with incorrectly formatted routes' do
            let(:cf_prod_routes) {{ 'some-prod-domain.io' => 'some-prod-host' }}

            it 'raises' do
              expect { cf_credentials.routes }.to raise_error(/Hosts in credentials must be nested as an array/)
            end
          end

          context 'when all hosts for a domain are nil' do
            let(:cf_prod_routes) {{ 'some-prod-domain.io' => nil }}

            it 'raises' do
              expect { cf_credentials.routes }.to raise_error(/Did you mean to add a list of hosts for domain some-prod-domain.io/)
            end
          end

          context 'when a host is nil' do
            let(:cf_prod_routes) {{ 'some-prod-domain.io' => [nil] }}

            it 'raises' do
              expect { cf_credentials.routes }.to raise_error(/Did you mean to provide a hostname for the domain some-prod-domain.io/)
            end
          end
        end
      end

      describe '#cf_credentials' do
        it 'returns the routes for the requested environment' do
          expect(config.cf_credentials('production').routes).to eq('some-prod-domain.io'=>['some-prod-host'])
        end

        it 'returns the space for the requested environment' do
          expect(config.cf_credentials('production').space).to eq('some-prod-space')
        end
      end

      it 'fetches the credentials repository only when the credentials are asked for' do
        config.book_repo
        expect(RemoteYamlCredentialProvider).to_not have_received(:new)
        config.aws_credentials
        expect(RemoteYamlCredentialProvider).to have_received(:new)
      end

      it 'only fetches the credentials repository once' do
        expect(RemoteYamlCredentialProvider).to receive(:new).once
        config.aws_credentials
        config.cf_credentials('staging')
        config.cf_credentials('production')
        config.aws_credentials
      end
    end

    describe 'equality' do
      let(:config_hash_1) do
        {'a' => 'b', c: 'd'}
      end

      let(:config_hash_2) do
        {'a' => 'b', c: 'e'}
      end

      it 'is true for identical configurations' do
        expect(Configuration.new(logger, config_hash_1)).to eq(Configuration.new(logger, config_hash_1))
      end

      it 'is false for different configurations' do
        expect(Configuration.new(logger, config_hash_1)).not_to eq(Configuration.new(logger, config_hash_2))
      end
    end

    describe '#has_option?' do
      let(:config) { Configuration.new(logger, {'foo' => 'bar'}) }

      context 'when the configuration has the option' do
        it 'should return true' do
          expect(config.has_option?('foo')).to eq(true)
        end
      end

      context 'when the configuration does not have the option' do
        it 'should return false' do
          expect(config.has_option?('bar')).to eq(false)
        end
      end
    end
  end
end
