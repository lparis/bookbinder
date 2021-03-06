require 'find'
require 'pathname'
require 'nokogiri'

module Bookbinder

  class LocalFileSystemAccessor
    def file_exist?(path)
      File.exist?(path)
    end

    def write(to: nil, text: nil)
      make_directory(File.dirname to)

      File.open(to, 'a') do |f|
        f.write(text)
      end

      to
    end

    def read(path)
      File.read(path)
    end

    def remove_directory(path)
      FileUtils.rm_rf(path)
    end

    def make_directory(path)
      FileUtils.mkdir_p(path)
    end

    def copy(src, dest)
      unless File.directory?(dest)
        FileUtils.mkdir_p(dest)
      end

      FileUtils.cp_r src, dest
    end

    def copy_contents(src, dest)
      unless File.directory?(dest)
        FileUtils.mkdir_p(dest)
      end

      contents = Dir.glob File.join(src, '**')
      contents.each do |dir|
        FileUtils.cp_r dir, dest
      end
    end

    def copy_including_intermediate_dirs(file, root, dest)
      path_within_destination = relative_path_from(root, file)
      extended_dest = File.dirname(File.join dest, path_within_destination)
      copy file, extended_dest
    end

    def rename_file(path, new_name)
      new_path = File.expand_path File.join path, '..', new_name
      File.rename(path, new_path)
    end

    def find_files_with_ext(ext, path)
      Dir[File.join path, "**/*.#{ext}"]
    end

    def relative_path_from(src, target)
      target_path = Pathname(File.absolute_path target)
      relative_path = target_path.relative_path_from(Pathname(File.absolute_path src))
      relative_path.to_s
    end

  end

end
