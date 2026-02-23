require 'httparty'
require 'json'
require 'time'
require 'tzinfo'

# CheckIn
# https://balbuton.com/api/v1/members_checkin/addcheckin/1592456
# {"date":"2026-02-22T09:26:30-06:00","users":["176064"]}

class BallButton
  include HTTParty

  COURT_5 = 1176
  COURT_5C = 1178
  COURT_5D = 1179
  COURT_6A = 1180
  COURT_6B = 1181
  API_URL  = '/api/v1'
  BOOK_URL = "#{API_URL}/appointment/add_book"
  LIST_URL = "#{API_URL}/members/booking"
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
    '6B' => COURT_6B
  }

  headers(
    'Content-Type' => 'application/json',
    'x-location-id': '134',
    'x-facility-group-id': '144'
  )
  base_uri(BASE_URL)

  def initialize(user = ENV['BB_USER'])
    @user = user || 'Michael Crockett'
  end

  def user_id
    USERS[@user].first.to_s
  end

  def user_token
    USERS[@user].last
  end

  def user_token_header
    { 'x-access-token': user_token }
  end

  def bookings
    url = "#{LIST_URL}/#{user_id}"

    data = {
      startDate:"2026-02-01T00:00:00-06:00",
      endDate:"2026-02-28T23:59:59-06:00",
    type:"0",
    is_coach:false}

    BallButton.post(url, body: data.to_json,headers: user_token_header)
  end

  def checkin
  end

  def reserve(start, minutes: nil, court: nil, dry_run: false)
    minutes ||= 60
    court ||= COURT_5
    court = COURTS[court] || court
    court = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ALL'
    attempts = [COURT_5C, COURT_5D, COURT_6A, COURT_6B] if court.to_s.upcase == 'ANY'

    next_week = Time.now + (7 * 24 * 60 * 60)
    (hr, min) = start.split(':')
    start_time = CHICAGO_TZ.local_time(next_week.year, next_week.month, next_week.day, hr.to_i, min.to_i, 0)
    end_time = start_time + (60 * minutes.to_i)

    (attempts || [court]).each do |c|
      data = {
        start_time: start_time.utc.iso8601,
        end_time: end_time.utc.iso8601,
        instantBook: true,
        courts: [c].flatten,
        userId: user_id,
        force: false,
        sport_id: '1',
        fullName: @user,
        assigned: [],
        tags: [],
        partners: [],
        guests: [],
        add_on_id: nil
      }

      puts data.to_json

      @response = if dry_run
                   BallButton.get('', headers: user_token_header)
                 else
                   BallButton.post(BOOK_URL, body: data.to_json,
                                 headers: user_token_header)
                 end
      return @response if @response.ok?
    end

    @response
  end
end

@bb = BallButton.new(ENV['BB_USER'])

if( 'checkin' == ARGV[0])
@bb.bookings
else
@bb.reserve(
  ENV['RESERVE_START'],
  court: ENV['COURT'],
  dry_run: 'true' == ENV['DRY_RUN'],
  minutes: ENV['D']
).parsed_response
end
