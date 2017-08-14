require 'highline/import'
require 'optparse'
require 'fileutils'
require 'byebug'

class PlaylistRandomizer
  FILE_GLOB = "**/*.mp3"

  def initialize(params = {})
    directory = params[:input] || File.join('', 'Users', 'mcrockett', 'DreamObjects', 'Music')
    @mp3s   = Dir.glob(File.join(directory, FILE_GLOB))
    @output = params[:output]
    @append = params[:append] || false
    @debug  = params[:debug] || false
    @playlist = []
    errors  = []

    if (0 == @mp3s.size)
      errors << "No mp3s found in '#{directory}'"
    end

    if ((nil == @output) || (false == Dir.exist?(@output)))
      errors << "Output directory not found '#{@output}'"
    elsif ((false == @append) && (0 != Dir.glob(File.join(@output, FILE_GLOB)).size))
      errors << "Already files in the output directory. Maybe you want to use '--append' option?"
    end

    if (false == errors.empty?)
      puts "#{errors * " AND\n"}.\nRun with -h to see usage."
      exit 1
    end
  end

  def process
    selected = []

    if (true == @append)
      Dir.glob(File.join(@output, FILE_GLOB)).each do |file|
        @playlist << file
        selected  << File.basename(file)[prefix.size..-1]
      end
    end

    if (true == @debug)
      @mp3s = @mp3s.first(10)
    end

    @mp3s.each do |mp3|
      basename = File.basename(mp3)

      if (true == selected.include?(basename))
        puts("Keeping '#{basename}' in playlist.")
      else
        result = ask("#{File.basename(mp3)}? ")
        result.strip!
        result.downcase!

        if (('q' == result) || ('exit' == result))
          break
        elsif ((false == result.empty?) && ('n' != result) && ('no' != result))
          @playlist << mp3
        end
      end
    end

    @playlist.shuffle!

    @playlist.each_with_index do |mp3, i|
      basename = File.basename(mp3)

      if (@output == File.dirname(mp3))
        basename = basename[prefix.size..-1]
      end

      dest = File.join(@output, "#{prefix(i)}#{basename}")

      if (@output == File.dirname(mp3))
        FileUtils.mv(mp3, dest)
      else
        FileUtils.cp(mp3, dest)
      end
    end
  end

  private
  def prefix(i = 0)
    return "#{'%03d' % i}_"
  end
end

options = {}
OptionParser.new do |opt|
  opt.on('--input DIRECTORY', 'Specify input directory.') { |o| options[:input] = o }
  opt.on('--output DIRECTORY', 'Specify output directory.') { |o| options[:output] = o }
  opt.on('--append', 'Change to append mode.') { |o| options[:append] = o }
  opt.on('--debug', 'Change to debug mode.') { |o| options[:debug] = o }
end.parse!

PlaylistRandomizer.new(options).process
