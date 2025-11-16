require 'nokogiri'
require 'httparty'
require 'byebug'
require 'fileutils'

class RingerPodcastParser
  #PLAYER_MOUNT = '/run/media/mcrockett/Q7S/'
  PLAYER_MOUNT = '/Volumes/Q7S/'

  def reader_api
    @response_json ||= HTTParty.get(
      'http://reader.mmcrockett.com/api/entries',
      headers: {
        'Content-Type': 'application/json; charset=utf-8'
      },
      query: {
        timestamp: 1_706_802_269_486
      }
    ).parsed_response
  end

  def initialize(query)
    url = query if query.start_with?('http')

    url ||= reader_api.find { |entry| query.to_i == entry['id'] }['link'] if query.to_s == query.to_i
    url ||= reader_api.find { |entry| entry['subject'].downcase.include?(query.downcase) }['link']

    @html_raw = HTTParty.get(url).body
  end

  def process
    filename = find_title.split(':').last.strip.gsub(/\W/, '')[0..16]
    filename = "/tmp/#{filename.split('on').first}"
    filenamefull = "#{filename}.mp3"

    url = find_mp3_link

    if false == File.exist?(filenamefull)
      File.open(filenamefull, 'wb') do |file|
        frags = 0

        response = HTTParty.get(url, stream_body: true) do |fragment|
          if [301, 302].include?(fragment.code)
            print 'o'
          elsif fragment.code == 200
            print '.' if (frags % 100).zero?
            file.write(fragment)
            frags += 1
          else
            raise StandardError, "Non-success status code while streaming #{fragment.code}"
          end
        end
      end
    end

    puts
    puts "Successful: #{filenamefull}"
    print 'Splitting...'

    raise 'Failed to split' if false == system("mp3splt -S 3 -o @f@n2 -Q #{filenamefull}")

    puts 'done'

    FileUtils.rm_f(filenamefull) if File.exist?(filenamefull)
    puts "Removed #{filenamefull}"
 
    if Dir.exist?(PLAYER_MOUNT)
      (0..10).each do |i|
        Dir.glob("#{filename}0#{i}.mp3").each do |file|
          print "Moving #{file}..."
          FileUtils.mv(file, PLAYER_MOUNT)
          puts 'done'
        end
      end
    end
  end

  def find_title(html = @html_raw)
    page = Nokogiri::HTML(html)
    page.css('title').first.text.strip
  end

  def find_mp3_link(html = @html_raw)
    script_line = html.lines.find { |l| l.include?('traffic') }
    asset_url_index = script_line.index('assetUrl')
    asset_url_index ||= script_line.index('actionUrl')
    http_start = script_line.index('http', asset_url_index)
    url_end = script_line.index(/[?|\\]/, http_start) - 1

    script_line[http_start..url_end]
  end
end

RingerPodcastParser.new(ARGV[0]).process
