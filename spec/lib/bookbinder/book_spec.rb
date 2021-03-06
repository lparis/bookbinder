require_relative "../../../lib/bookbinder/directory_helpers"
require_relative "../../../lib/bookbinder/book"
require_relative '../../helpers/tmp_dirs'
require_relative '../../helpers/nil_logger'

module Bookbinder
  include Bookbinder::DirectoryHelperMethods
  describe Book do
    include_context 'tmp_dirs'

    let(:logger) { NilLogger.new }
    let(:sections) do
      [{
           'repository' => {
               'name' => 'fantastic/dogs-repo'
           },
           'directory' => 'dogs'
       }]
    end

    let(:book_name) { 'wow-org/such-book' }
    let(:git_accessor) { double('git_accessor') }
    let(:book) { Book.new(full_name: 'test', git_accessor: git_accessor) }
    let(:repo) { double(GitHubRepository) }

    describe '#tag_self_and_sections_with' do
      let(:desired_tag) { 12.times.map { (65 + rand(26)).chr }.join }

      it 'should tag itself and the repos for each section' do
        sections.each do |s|
          doc_repo = double
          expect(GitHubRepository).to receive(:new).with(
            logger: logger,
            full_name: s['repository']['name'],
            git_accessor: git_accessor
          ).and_return(doc_repo)
          expect(doc_repo).to receive(:tag_with).with(desired_tag)
        end

        self_repo = double
        expect(GitHubRepository).to receive(:new).with(
          logger: logger,
          full_name: book_name,
          github_token: nil,
          git_accessor: git_accessor
        ).and_return(self_repo)
        expect(self_repo).to receive(:tag_with).with(desired_tag)

        book = Book.new(logger: logger, full_name: book_name, sections: sections, git_accessor: git_accessor)
        book.tag_self_and_sections_with(desired_tag)
      end
    end

    describe '#full_name' do
      it 'returns the name of the repository' do
        allow(GitHubRepository).to receive(:new).with(
          logger: nil,
          full_name: 'test',
          github_token: nil,
          git_accessor: git_accessor
        ).and_return(repo)
        expect(repo).to receive(:full_name).and_return('test')
        expect(book.full_name).to eq('test')
      end
    end

    describe '#head_sha' do
      it 'returns the sha of the latest commit' do
        allow(GitHubRepository).to receive(:new).with(
          logger: nil,
          full_name: 'test',
          github_token: nil,
          git_accessor: git_accessor
        ).and_return(repo)
        expect(repo).to receive(:head_sha).and_return('latest-sha')
        expect(book.head_sha).to eq('latest-sha')
      end
    end

    describe '#directory' do
      it 'returns the directory of the repository' do
        allow(GitHubRepository).to receive(:new).with(
          logger: nil,
          full_name: 'test',
          github_token: nil,
          git_accessor: git_accessor
        ).and_return(repo)
        expect(repo).to receive(:directory).and_return('test-dir')
        expect(book.directory).to eq('test-dir')
      end
    end

    describe '#copy_from_remote' do
      let(:destination_dir) { 'some-path' }
      let(:git_accessor) { double('git_accessor') }
      it 'copies the repository from the remote directory' do
        allow(GitHubRepository).to receive(:new).with(
          logger: nil,
          full_name: 'test',
          github_token: nil,
          git_accessor: git_accessor
        ).and_return(repo)
        expect(repo).to receive(:copy_from_remote).
          with(destination_dir, 'master').
          and_return(destination_dir)
        expect(book.copy_from_remote(destination_dir)).to eq(destination_dir)
      end
    end

    describe '.from_remote' do
      let(:temp_workspace) { tmp_subdir('workspace') }
      let(:ref) { 'this-is-a-tag' }
      let(:full_name) { 'foo/book' }
      let(:destination_dir) { 'some-path' }
      let(:new_book) { double(Book) }

      it 'creates a new Book' do
        expect(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: git_accessor)
                        .and_return(new_book)
        allow(new_book).to receive(:copy_from_remote)
        Book.from_remote(logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref, git_accessor: git_accessor)
      end

      context 'when the destination dir is set' do
        it 'copies the book from remote' do
          allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: git_accessor)
                         .and_return(new_book)
          expect(new_book).to receive(:copy_from_remote).with(destination_dir)
          Book.from_remote(
              logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref, git_accessor: git_accessor)
        end
      end

      context 'when the destination dir is not set' do
        it 'copies the book from remote' do
          allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: git_accessor)
                         .and_return(new_book)
          expect(new_book).to_not receive(:copy_from_remote)
          Book.from_remote(
              logger: logger, full_name: full_name, ref: ref, git_accessor: git_accessor)
        end
      end

      it 'returns the book' do
        allow(Book).to receive(:new).with(logger: logger, full_name: full_name, target_ref: ref, git_accessor: git_accessor)
                        .and_return(new_book)
        allow(new_book).to receive(:copy_from_remote)
        expect(Book.from_remote(logger: logger, full_name: full_name, destination_dir: destination_dir, ref: ref, git_accessor: git_accessor)).to eq(new_book)
      end
    end
  end
end
