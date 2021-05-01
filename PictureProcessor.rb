#!/usr/bin/env ruby

require 'optparse'
require 'date'
require 'fileutils'
require 'ostruct'

class PictureProcessor
  DEFAULT_GROUP_N = 10

  def initialize(options)
    @grouping_size = options[:grouping_n] || DEFAULT_GROUP_N
    @indir         = options[:indir]
    @outdir        = options[:outdir]
    @command_type  = nil

    raise 'Bad indir' unless Dir.exist?(@indir)
    raise 'Bad outdir' unless Dir.exist?(@outdir)

    %w[sips convert].each do |cmd|
      @command_type = cmd if system("#{cmd} --help #{devnull}")
    end

    raise 'Requires sips or imagemagick installation' if @command_type.nil?
  end

  def process
    groups = {}

    pictures.each do |picture|
      if (File.file?(picture))
        groups[File.mtime(picture).to_date] ||= []
        groups[File.mtime(picture).to_date] << resize(rename(picture))
      end
    end

    groups.each do |date, pictures|
      directory = File.join(@outdir, date.year.to_s)

      if (@grouping_size > pictures.size)
        directory = File.join(directory, date.strftime("%Y%m00"))
      else
        directory = File.join(directory, date.strftime("%Y%m%d"))
      end

      if (false == Dir.exist?(directory))
        FileUtils.mkdir_p(directory)
      end

      pictures.each { |picture| FileUtils.mv(picture, File.join(directory, File.basename(picture).gsub('.cp.', '.').gsub('.resize.', '.'))) }
    end
  end

  private
  def pictures
    return Dir.glob(File.join(@indir, '**', '*.jpg'), File::FNM_CASEFOLD)
  end

  def sips(new_name, original)
    ['sips', '-Z', '800', '--out', new_name, original] * ' '
  end

  def convert(new_name, original)
    ['convert', original, '-resize', '800x800', new_name] * ' '
  end

  def resize(picture)
    parts = file_parts(picture)
    name  = parts.name + '.resize' + parts.ext
    cmd   = send(@command_type, name, picture)

    if (File.file?(name))
      puts "Skipping '#{picture}', already exists."
    else
      raise "#{cmd}" unless system(cmd)
    end

    return name
  end

  def rename(picture)
    parts = file_parts(picture)
    name  = picture

    if (parts.ext.downcase != parts.ext)
      name = parts.name + '.cp' + parts.ext.downcase
      FileUtils.cp(picture, name) unless File.file?(name)
    end

    return name
  end

  def file_parts(file)
    ext  = File.extname(file)
    name = file.chomp(ext)

    return OpenStruct.new(ext: ext, name: name)
  end

  def devnull
    return '> /dev/null 2>&1'
  end
end

options = {}
OptionParser.new do |opt|
  opt.banner = <<-EOF
   Usage: PictureProcessor.rb [options] 

   Renames files, resizes and moves the resized to backup location
  EOF
  opt.on('-d', '--indir name', 'Directory to process.') { |o| options[:indir] = o }
  opt.on('-o', '--outdir name', 'Directory for output.') { |o| options[:outdir] = o }
  opt.on('-g', '--grouping n', 'Number of pictures to give their own date subfolder') { |o| options[:grouping_n] = o.to_i }
end.parse!

PictureProcessor.new(options).process
