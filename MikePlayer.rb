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
  PL_FILE_ENDING     = '.mpl'.freeze

  def initialize(options, *args)
    @pl_data   = {found_song_count: 0, loaded_song_count: 0, playlist_name: ''}
    @shuffle   = (options[:shuffle] == true)
    @overwrite = (options[:overwrite] == true)
    @volume    = options[:volume] || DEFAULT_VOLUME
    @directory = options[:directory] || DEFAULT_DIRECTORY
    @minutes   = options[:minutes].to_i
    @random    = options[:random].to_i
    @playlist  = determine_playlist(options[:playlist])
    @songs     = []
    @command   = ''
    @pid       = nil
    @state     = STOPPED
    @song_i    = 0
    @start_time = nil

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

    if (0 < @random)
      files = Dir.glob(File.join(@directory, "**", "*.mp3"), File::FNM_CASEFOLD)

      files.shuffle!

      files.take(@random).each do |f|
        self << f
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

    sleep 0.2

    if (true == pid_alive?)
      kill("KILL")
    end

    @state = STOPPED
  end

  def pid_alive?(pid = @pid)
    if (false == pid.nil?)
      return system("ps -p #{pid} > /dev/null")
    end

    return false
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

  def pause_if_over_time_limit
    if (false == @start_time.nil?) && (0 < @minutes) && (true == playing?)
      if (0 > minutes_remaining)
        press_pause
        @start_time = nil
        @minutes    = 0
      end
    end
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

        while (true == pid_alive?)
          pause_if_over_time_limit

          if (true == playing?)
            indicator = "#{'>' * (play_ticks % 4)}"
            play_ticks += 1
            info_changed = true
          elsif (true == paused?) && (PAUSE_INDICATOR != indicator)
            indicator = PAUSE_INDICATOR
            info_changed = true
          end

          if (true == info_changed)
            mindicator = ""

            if (0 < minutes_remaining)
              mindicator = "(#{minutes_remaining}↓) "
            end

            info  = "#{info_prefix} #{as_duration_str(song_info.length, (play_ticks * SLEEP_SETTING).to_i)} #{mindicator}#{indicator}".ljust(max_size)

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
      elsif ('t' == @command)
        @start_time = Time.now
      elsif (false == @start_time.nil?) && ("#{@command.to_i}" == @command)
        if (0 == @minutes)
          @minutes = @command.to_i
        else
          @minutes *= 10
          @minutes += @command.to_i
        end
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
      @pl_data[:playlist_name] = File.basename(user_option, PL_FILE_ENDING)

      if (true == File.exist?(user_option))
        return user_option
      end
    elsif (0 < @random)
      @pl_data[:playlist_name] = "random_n#{@random}"
    else
      @pl_data[:playlist_name] = 'default'
    end

    return File.join(SETTINGS_DIRECTORY, "#{@pl_data[:playlist_name]}#{PL_FILE_ENDING}")
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
      if ((true == @overwrite) || (0 < @random))
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

  def minutes_remaining
    if ((0 == @minutes) || (@start_time.nil?))
      return -1
    else
      return (@minutes - ((Time.now - @start_time).to_i / 60).to_i)
    end
  end
end

options = {}
OptionParser.new do |opt|
  opt.banner = "Usage: MikePlayer.rb [options] <song name seach>"
  opt.on('-s', '--shuffle', 'Shuffle playlist.') { |o| options[:shuffle] = true }
  opt.on('-r', '--random n', 'Create playlist with randomly picked n songs.') { |o| options[:random] = o.to_i }
  opt.on('-o', '--overwrite', 'Overwrite playlist.') { |o| options[:overwrite] = true }
  opt.on('-v', '--volume', 'Changes default volume.') { |o| options[:volume] = o }
  opt.on('-p', '--playlist name', 'Play playlist name.') { |o| options[:playlist] = o }
  opt.on('-d', '--directory name', 'Directory to find mp3s.') { |o| options[:directory] = o }
  opt.on('-t', '--time minutes', 'Limit time to number of minutes.') { |o| options[:minutes] = o }
end.parse!

mikeplayer = MikePlayer.new(options, ARGV)
mikeplayer.play
