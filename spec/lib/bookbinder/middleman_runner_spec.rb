require_relative '../../../lib/bookbinder/middleman_runner'
require_relative '../../../lib/bookbinder/values/section'
require_relative '../../../lib/bookbinder/book'
require_relative '../../helpers/nil_logger'
require_relative '../../helpers/middleman'

module Bookbinder
  describe MiddlemanRunner do
    include SpecHelperMethods

    UNEXERCISED_GIT_ACCESSOR = "UNEXERCISED_GIT_ACCESSOR"

    let(:logger) { NilLogger.new }
    let(:middleman_runner) { MiddlemanRunner.new(logger, UNEXERCISED_GIT_ACCESSOR) }

    let(:target_dir_path) { Dir.mktmpdir }
    let(:template_variables) { {'anybody' => 'nobody'} }
    let(:production_host) { double }
    let(:archive_menu) { {} }
    let(:verbose) { false }
    let(:sections) { [
        Section.new('path/to/repo', '', true, 'my_subnav_template', 'path/to', 'my/place/rocks'),
        Section.new('path/to/repo', '', true, nil, 'path/to', 'fraggles/rock')
    ] }
    let(:local_repo_dir) { '/dev/null' }

    def run_middleman
      subnav_templates = {
          'my_place_rocks' => 'my_subnav_template',
          'fraggles_rock' => 'default'
      }

      middleman_runner.run(target_dir_path, 'master_middleman/source/public', template_variables, local_repo_dir, verbose, subnav_templates, production_host, archive_menu)
    end

    it 'invokes Middleman in the requested directory' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      working_directory_path = nil
      allow(build_command).to receive(:invoke) { working_directory_path = `pwd`.strip }

      run_middleman

      expect(Pathname.new(working_directory_path).realpath).to eq(Pathname.new(target_dir_path).realpath)
    end

    it 'tells middleman about template variables' do
      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:template_variables]).to eq(template_variables)
    end

    it 'tells middleman the production host' do
      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:production_host]).to eq(production_host)
    end

    it 'tells middleman the archive menu' do
      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:archive_menu]).to eq(archive_menu)
    end

    it 'tells middleman not to use relative links' do
      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:relative_links]).to eq false
    end

    it 'tells middleman about subnav_templates' do
      templates = {
          'my_place_rocks' => 'my_subnav_template',
          'fraggles_rock' => 'default'
      }

      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:subnav_templates]).to eq(templates)
    end

    it 'tells middleman about local_repo_dir' do
      run_middleman

      middleman_instance = Middleman::Cli::Build.shared_instance(verbose)
      expect(middleman_instance.config[:local_repo_dir]).to eq local_repo_dir
    end

    it 'builds with middleman and passes the verbose parameter' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})
      expect(build_command).to receive(:invoke).with(:build, [], {:verbose => verbose})

      run_middleman
    end

    it 'clears its shared_instance list' do
      old_instance = Middleman::Cli::Build.shared_instance(verbose)
      run_middleman
      expect(Middleman::Cli::Build.shared_instance(verbose)).to_not eq(old_instance)
    end

    it 'sets the MM root for invocation' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      invocation_mm_root = nil
      allow(build_command).to receive(:invoke) { invocation_mm_root = ENV['MM_ROOT'] }

      run_middleman

      expect(invocation_mm_root).to eq(target_dir_path)
    end

    it 'resets the MM root in cleanup' do
      build_command = expect_to_receive_and_return_real_now(Middleman::Cli::Build, :new, [], {:quiet => !verbose}, {})

      original_mm_root = ENV['MM_ROOT']

      ENV['MM_ROOT'] = 'anything'

      allow(build_command).to receive(:invoke)

      run_middleman

      expect(ENV['MM_ROOT']).to eq('anything')

      ENV['MM_ROOT'] = original_mm_root
    end
  end
end
