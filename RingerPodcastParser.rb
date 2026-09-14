require 'nokogiri'
require 'httparty'
require 'byebug'
require 'fileutils'
require 'json'
require 'set'

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

    @url = url
    @mp3_link = nil
    @html_raw = HTTParty.get(url).body
  end

  def process
    episode_name, link = find_episode
    @mp3_link = link

    temp_base = "/tmp/#{episode_name.gsub(/\W/, '')[0..16]}"
    filenamefull = "#{temp_base}.mp3"

    url = @mp3_link || find_mp3_link

    if !File.exist?(filenamefull) || File.size(filenamefull).zero?
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

    split_files = Dir.glob("#{temp_base}*.mp3").sort_by { |f| f[/(\d+)\.mp3$/, 1].to_i }
    renamed_files = split_files.each_with_index.map do |file, idx|
      new_name = "/tmp/#{smart_filename(episode_name, idx + 1)}.mp3"
      FileUtils.mv(file, new_name)
      new_name
    end

    if Dir.exist?(PLAYER_MOUNT)
      renamed_files.each do |file|
        print "Copying #{file}..."
        FileUtils.cp(file, PLAYER_MOUNT)
        sleep(20)
        print "removing #{file}..."
        FileUtils.rm(file)
        puts 'done'
      end
    end
  end

  def find_title(html = @html_raw)
    page = Nokogiri::HTML(html)
    page.css('title').first.text.strip
  end

  def find_episode(html = @html_raw)
    episodes = episodes_from_json(html)
    raise 'No episodes found in page JSON' if episodes.empty?

    slug_tokens = normalize(@url.to_s.split('/')[-2].to_s)
    match = episodes.find { |name, _link| normalize(name) == slug_tokens }
    match ||= episodes.max_by { |name, _link| (normalize(name) & slug_tokens).size }

    match
  end

  def find_mp3_link(html = @html_raw)
    find_episode(html).last
  end

  private

  def smart_filename(title, part_number)
    words = title.split(/\s+/).map { |w| w.gsub(/[^A-Za-z0-9]/, '') }.reject(&:empty?)

    prefix = ''
    until words.empty?
      candidate = prefix + words.first
      break if candidate.length >= 8

      prefix = candidate
      words.shift
    end

    "#{prefix}#{part_number}#{words.join}"
  end

  def episodes_from_json(html)
    blobs = html.scan(%r{<script[^>]*type="application/json"[^>]*>(.*?)</script>}m).flatten
    episodes = []

    blobs.each do |blob|
      data = JSON.parse(blob)
      walk_json(data) do |node|
        next unless node.is_a?(Hash) && node['mediaEnclosures'].is_a?(Array)

        stream_url = node['mediaEnclosures'].map { |m| m['streamUrl'] }.compact.first
        name = node['name'] || node['title']
        episodes << [name, stream_url] if name && stream_url
      end
    end

    episodes.uniq
  end

  def walk_json(node, &block)
    case node
    when Hash
      yield node
      node.each_value { |v| walk_json(v, &block) }
    when Array
      node.each { |v| walk_json(v, &block) }
    end
  end

  def normalize(str)
    str.to_s.downcase.gsub(/[^a-z0-9]+/, ' ').split.to_set
  end
end

RingerPodcastParser.new(ARGV[0]).process
