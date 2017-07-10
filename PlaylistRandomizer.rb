require 'highline/import'
require 'optparse'
require 'fileutils'
require 'byebug'

class PlaylistRandomizer
  def initialize(params = {})
    directory = params[:input] || File.join('', 'Users', 'mcrockett', 'DreamObjects', 'Music')
    @mp3s   = Dir.glob(File.join(directory, '**/*.mp3'))
    @output = params[:output]
    errors  = []

    if (0 == @mp3s.size)
      errors << "No mp3s found in '#{directory}'"
    end

    if ((nil == @output) || (false == Dir.exist?(@output)))
      errors << "Output directory not found '#{@output}'"
    end

    if (false == errors.empty?)
      raise "\n#{errors * " AND\n"}.\nRun with -h to see usage."
    end
  end

  def process
    playlist = []
    size     = 0

    @mp3s.first(10).each do |mp3|
      result = ask("#{File.basename(mp3)}? ")

      if ((nil != result) && (false == result.empty?) && ('n' != result.downcase) && ('no' != result.downcase))
        playlist << mp3
      end
    end

    playlist.shuffle!

    playlist.each_with_index do |mp3, i|
      dest = File.join(@output, "#{'%03d' % i}_#{File.basename(mp3)}")
      FileUtils.cp(mp3, dest)
    end
  end
end

options = {}
OptionParser.new do |opt|
  opt.on('--input DIRECTORY', 'Specify input directory.') { |o| options[:input] = o }
  opt.on('--output DIRECTORY', 'Specify output directory.') { |o| options[:output] = o }
end.parse!

PlaylistRandomizer.new(options).process
