require 'optparse'
require 'json'
require 'open3'
require 'io/console'
require 'mp3info'

class MikePlayer
  DEFAULT_DIRECTORY  = File.join(Dir.home, 'Music')
  DEFAULT_VOLUME     = 0.2
  SETTINGS_DIRECTORY = File.join(Dir.home, '.mikeplayer')
  PAUSE_INDICATOR    = " ||".freeze
  SLEEP_SETTING      = 0.5
  STOPPED            = :stopped
  PLAYING            = :playing
  PAUSED             = :paused

  def initialize(options, *args)
    @pl_data   = {found_song_count: 0, loaded_song_count: 0, playlist_name: ''}
    @shuffle   = (options[:shuffle] == true)
    @replace   = (options[:replace] == true)
    @volume    = options[:volume] || DEFAULT_VOLUME
    @directory = options[:directory] || DEFAULT_DIRECTORY
    @minutes   = options[:minutes].to_i
    @playlist  = determine_playlist(options[:playlist])
    @songs     = []
    @command   = ''
    @pid       = nil
    @state     = STOPPED
    @song_i    = 0

    check_system
    preprocess_playlist

    args.flatten.each do |arg|
      if (true == File.file?(arg))
        self << arg
      else
        Dir.glob(File.join(@directory, "**", "*#{arg}*"), File::FNM_CASEFOLD).each do |f|
          self << f
        end
      end
    end

    write_playlist
  end

  def <<(song)
    if ((true == File.file?(song)) && (false == @songs.include?(song)))
      @pl_data[:found_song_count] += 1
      @songs << song
    end

    return self
  end

  def playing?
    return (PLAYING == @state)
  end

  def paused?
    return (PAUSED == @state)
  end

  def press_pause
    if (true == playing?)
      kill("STOP")
      @state = PAUSED
    elsif (true == paused?)
      kill("CONT")
      @state = PLAYING
    else
      print("Confused state #{@state}.")
    end
  end

  def stop_song
    if (true == paused?)
      kill("CONT")
    end

    kill("INT")
    @state = STOPPED
  end

  def next_song
    stop_song

    @song_i += 1
  end

  def previous_song
    stop_song

    @song_i -= 1

    if (@song_i < 0)
      @song_i = 0
    end
  end

  def kill(signal)
    if (false == @pid.nil?)
      Process.kill(signal, @pid)
    end
  end

  def display(info, filename)
    artist = "#{info.tag.artist}"
    title  = "#{info.tag.title}"

    if (true == artist.empty?) && (true == title.empty?)
      return File.basename(filename, '.mp3')
    elsif (true == artist.empty?)
      artist = "?????"
    elsif (true == title.empty?)
      title  = "?????"
    end

    return "#{artist} - #{title}"
  end

  def play
    print "Playlist #{@pl_data[:playlist_name]} loaded #{@pl_data[:loaded_song_count]} songs, added #{@pl_data[:found_song_count]}\n"
    song_data = []

    if (true == @shuffle)
      @songs.shuffle!
    end

    @songs.each do |song|
      song_data << Mp3Info.new(song)
    end

    if (0 != @minutes)
      time = 0

      @songs.each_with_index do |song, i|
        time += song_data[i].length.ceil

        if (@minutes < (time/60).to_i)
          @songs = @songs[0..i - 1]
          break
        end
      end

      print "Time limit set to #{@minutes} minutes, only playing #{@songs.size} songs.\n"
    end

    thread = Thread.new do
      song_count = "#{@songs.size}"
      max_size   = 0

      while (@song_i < @songs.size)
        song = @songs[@song_i]
        song_info = song_data[@song_i]
        play_ticks = 0
        song_i_str = "#{@song_i + 1}".rjust(song_count.size)
        info_prefix = "\rPlaying (#{song_i_str}/#{song_count}): #{display(song_info, song)}".freeze
        stdin, stdother, thread_info = Open3.popen2e("play --no-show-progress --volume #{@volume} #{song}")
        @state   = PLAYING
        @pid     = thread_info.pid
        indicator = ''

        while (true == system("ps -p #{@pid} > /dev/null"))
          if (true == playing?)
            indicator = "#{'>' * (play_ticks % 4)}"
            play_ticks += 1
            info_changed = true
          elsif (true == paused?) && (PAUSE_INDICATOR != indicator)
            indicator = PAUSE_INDICATOR
            info_changed = true
          end

          if (true == info_changed)
            info  = "#{info_prefix} #{as_duration_str(song_info.length, (play_ticks * SLEEP_SETTING).to_i)} #{indicator} ".ljust(max_size)

            max_size = info.size

            print(info)

            $stdout.flush
          end

          sleep SLEEP_SETTING
        end

        stdin.close
        stdother.close

        @pid = nil

        if (true == playing?)
          next_song
        end
      end

      @pid   = nil
      puts ""
      exit
    end

    while ('q' != @command)
      @command = STDIN.getch

      if ('c' == @command)
        press_pause
      elsif ('v' == @command)
        next_song
      elsif ('z' == @command)
        previous_song
      elsif ('q' == @command) && (false == @pid.nil?)
        stop_song
        thread.kill
      end
    end

    puts ""
  end

  def cmd_exist?(cmd)
    if (true != system('command'))
      raise "Missing 'command' command, which is used to test compatibility."
    end

    if (true != system("command -v #{cmd} >/dev/null 2>&1"))
      return false
    end

    return true
  end

  private
  def as_duration_str(l, t)
    l_min = "%02d" % (l / 60).floor
    l_sec = "%02d" % (l % 60)
    e_min = "%02d" % (t / 60).floor
    e_sec = "%02d" % (t % 60)

    return "#{e_min}:#{e_sec} [#{l_min}:#{l_sec}]"
  end

  def determine_playlist(user_option)
    if (false == user_option.nil?)
      if (false == File.exist?(user_option))
        @pl_data[:playlist_name] = user_option
        return File.join(SETTINGS_DIRECTORY, "#{user_option}.mpl")
      else
        @pl_data[:playlist_name] = File.basename(user_option)
        return user_option
      end
    else
      @pl_data[:playlist_name] = 'default'
      return File.join(SETTINGS_DIRECTORY, 'default.mpl')
    end
  end

  def write_playlist
    File.open(@playlist, 'w') do |f|
      f.puts(@songs.to_json)
    end
  end

  def preprocess_playlist
    if (false == Dir.exist?(SETTINGS_DIRECTORY))
      Dir.mkdir(SETTINGS_DIRECTORY)
    end

    if (true == File.file?(@playlist))
      if (true == @replace)
        File.delete(@playlist)
      else
        @songs = JSON.parse(File.read(@playlist))
        @pl_data[:loaded_song_count] = @songs.size
      end
    end
  end

  def check_system
    %w[play].each do |cmd|
      if (false == cmd_exist?(cmd))
        raise "#{cmd} failed, do you have sox installed?"
      end
    end

    return nil
  end
end

options = {}
OptionParser.new do |opt|
  opt.banner = "Usage: MikePlayer.rb [options] <song name seach>"
  opt.on('-s', '--shuffle', 'Shuffle playlist.') { |o| options[:shuffle] = true }
  opt.on('-r', '--replace', 'Replace playlist.') { |o| options[:replace] = true }
  opt.on('-v', '--volume', 'Changes default volume.') { |o| options[:volume] = o }
  opt.on('-p', '--playlist name', 'Play playlist name.') { |o| options[:playlist] = o }
  opt.on('-d', '--directory name', 'Directory to find mp3s.') { |o| options[:directory] = o }
  opt.on('-t', '--time minutes', 'Limit time to number of minutes.') { |o| options[:minutes] = o }
end.parse!

mikeplayer = MikePlayer.new(options, ARGV)
mikeplayer.play
