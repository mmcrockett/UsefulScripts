require 'httparty'
require 'json'
require 'time'
require 'tzinfo'

class BallButton
  include HTTParty

  COURT_5 = 1176
  COURT_5C = 1178
  COURT_5D = 1179
  COURT_6A = 1180
  COURT_6B = 1181
  API_URL = '/api/v1/appointment/add_book'
  BASE_URL = 'https://balbuton.com'
  CHICAGO_TZ = TZInfo::Timezone.get('America/Chicago')

  USERS = JSON.parse(
    File.read("#{__dir__}/ball_button.users.json")
  )

  COURTS = {
    '5' => COURT_5,
    '5C' => COURT_5C,
    '5D' => COURT_5D,
    '6A' => COURT_6A,
    '6B' => COURT_6B,
  }

  headers(
    'Content-Type' => 'application/json',
    'x-location-id': '134',
    'x-facility-group-id': '144'
  )
  base_uri(BASE_URL)

  def self.reserve(start, minutes: 90, court: nil, dry_run: false, user: nil)
    user ||= 'Michael Crockett'
    court ||= COURT_5
    court = COURTS[court] || court

    next_week = Time.now + (7 * 24 * 60 * 60)
    (hr, min) = start.split(':')
    (user_id, token) = USERS[user]
    start_time = CHICAGO_TZ.local_time(next_week.year, next_week.month, next_week.day, hr.to_i, min.to_i, 0)
    end_time = start_time + (60 * minutes)

    data = {
      start_time: start_time.utc.iso8601,
      end_time: end_time.utc.iso8601,
      instantBook: true,
      courts: [court],
      userId: user_id.to_s,
      force: false,
      sport_id: "1",
      fullName: user,
      assigned: [],
      tags: [],
      partners: [],
      guests: [],
      add_on_id: nil
    }

    puts data.to_json

    dry_run ? self.get('', headers: {'x-access-token': token}) : self.post(API_URL, body: data.to_json, headers: {'x-access-token': token})
  end
end

puts BallButton.reserve(
  ENV['RESERVE_START'],
  court: ENV['COURT'],
  dry_run: 'true' == ENV['DRY_RUN'],
  user: ENV['BB_USER']
).parsed_response
