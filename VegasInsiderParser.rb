require 'nokogiri'
require 'open-uri'
require 'byebug'

class VegasInsiderParser
  attr_reader :data

  FILE = File.join('', 'Users', 'mcrockett', 'UsefulScripts.mmcrockett', 'Page1.html')
  KEYS = [:away, :home, :away_percent, :home_percent, :away_confidence, :home_confidence]

  def initialize()
    @data = []

    puts "Loading: '#{FILE}'"
    page = Nokogiri::HTML(File.read(FILE))

    page.css('tr').each do |tr|
      game = []
      anchors = tr.css('a[href*="team-page"]')

      next if 2 != anchors.size
      anchors.each do |team|
        game << team.text
      end

      td = tr.css('td')[2]
      children = td.css('a').children
      idx = children.find_index {|child| child.text.match?(/(-)?(\d){1,2}/) && false == child.text.include?('u')}
      v   = children[idx].text.to_i
      v   = -v if idx > 3
      game << v

      puts "#{game.join(',')}"
    end
  end
end

puts "#{VegasInsiderParser.new}"
