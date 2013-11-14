require 'spec_helper'

describe DocRepoChangeMonitor do

  include_context 'tmp_dirs'

  describe '#build_necessary?' do
    subject { monitor.build_necessary? }

    let(:cached_sha_dir) { tmpdir }
    let(:cached_sha_file) { File.join(cached_sha_dir, 'cached_shas.yml') }
    let(:monitor) { DocRepoChangeMonitor.new repos, cached_sha_dir, 'github-username', 'github-password' }
    let(:repos) {  [{"github_repo" => "my-docs-org/my-docs-repo"},
                    {"github_repo" => "some-other-org/some-other-repo"}]
                }

    before do
      stub_github_ref_response 'my-docs-org/my-docs-repo', 'shaA'
      stub_github_ref_response 'some-other-org/some-other-repo', 'shaB'
    end

    context 'when no cached sha file is available' do
      before do
        expect(File.exist?(cached_sha_file)).to be_false
      end

      it { should be_true }

      it 'builds a new cached SHA file with the latest head SHAs' do
        subject
        expect(File.exist?(cached_sha_file)).to be_true
        expect(YAML.load(File.read(cached_sha_file))['my-docs-org/my-docs-repo']).to eq('shaA')
      end
    end

    context 'when the cached sha file is available but no entry exists for the repo' do
      before do
        write_cached_SHAs 'my-docs-org/my-docs-repo' => 'shaA'
      end

      it { should be_true }
    end

    context 'when cached SHAS are available and all SHAs are up to date' do
      before do
        write_cached_SHAs 'my-docs-org/my-docs-repo' => 'shaA', 'some-other-org/some-other-repo' => 'shaB'
      end

      it { should be_false }
    end

    context 'when cached SHAs are available but one is out of date' do
      before do
        write_cached_SHAs 'my-docs-org/my-docs-repo' => 'shaA', 'some-other-org/some-other-repo' => 'shaC'
      end

      it { should be_true }
    end
  end

  def stub_github_ref_response(repo_full_name, sha)
    json = <<JSON
{
  "ref": "refs/heads/master",
  "url": "https://api.github.com/repos/#{repo_full_name}/git/refs/heads/master",
  "object": {
    "sha": "#{sha}",
    "type": "commit",
    "url": "https://api.github.com/repos/#{repo_full_name}/git/commits/#{sha}"
  }
}
JSON
    head_ref_url = "https://github-username:github-password@api.github.com/repos/#{repo_full_name}/git/refs/heads/master"
    stub_request(:get, head_ref_url).to_return(:body => json, :headers => {'Content-Type' => 'application/json'})
  end

  def write_cached_SHAs(shas)
    yaml = YAML.dump(shas)
    File.open(cached_sha_file, 'w') { |f| f.write(yaml) }
  end
end