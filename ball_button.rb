require 'httparty'
require 'json'
require 'time'
require 'tzinfo'

class BallButton
  include HTTParty

  COURT_5 = 1176
  COURT_5A = 1179
  API_URL = '/api/v1/appointment/add_book'
  BASE_URL = 'https://balbuton.com'
  CHICAGO_TZ = TZInfo::Timezone.get('America/Chicago')

  USERS = {
  }

  headers(
    'Content-Type' => 'application/json',
    'x-location-id': '134',
    'x-facility-group-id': '144'
  )
  base_uri(BASE_URL)

  def self.reserve(start, minutes: 90, court: COURT_5, dry_run: false, user_id: nil)
    next_week = Time.now + (7 * 24 * 60 * 60)
    (hr, min) = start.split(':')
    (name, token) = USERS[user_id.to_s]
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
      fullName: name,
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

puts BallButton.reserve(ENV['RESERVE_START'], court: ENV['COURT'] || BallButton::COURT_5, dry_run: 'true' == ENV['DRY_RUN'], user_id: ENV['BB_USER_ID'] || '176064').parsed_response
