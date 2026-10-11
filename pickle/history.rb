require 'json'
require 'sqlite3'
require 'time'

# Default journal mode on purpose (no WAL) - the db lives on an NFS home dir.
module History
  DB_PATH = ENV['PICKLE_DB'] || "#{__dir__}/pickle.sqlite3"
  RETENTION_DAYS = 30

  SCHEMA = <<~SQL
    CREATE TABLE IF NOT EXISTS runs (
      id INTEGER PRIMARY KEY,
      started_at TEXT NOT NULL,
      finished_at TEXT,
      command TEXT NOT NULL,
      user TEXT,
      status TEXT NOT NULL DEFAULT 'running',
      summary TEXT,
      detail TEXT
    );
    CREATE TABLE IF NOT EXISTS requests (
      id INTEGER PRIMARY KEY,
      run_id INTEGER NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
      created_at TEXT NOT NULL,
      context TEXT,
      method TEXT NOT NULL,
      url TEXT NOT NULL,
      attempt INTEGER NOT NULL DEFAULT 1,
      status INTEGER,
      duration_ms INTEGER,
      request_body TEXT,
      response_body TEXT,
      error TEXT
    );
    CREATE INDEX IF NOT EXISTS requests_run_id ON requests(run_id);
    CREATE INDEX IF NOT EXISTS runs_started_at ON runs(started_at);
    CREATE TABLE IF NOT EXISTS bookings (
      id TEXT PRIMARY KEY,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      court TEXT,
      checked_in INTEGER NOT NULL DEFAULT 0,
      refreshed_at TEXT NOT NULL
    );
  SQL

  class << self
    def db
      @db ||= SQLite3::Database.new(DB_PATH).tap do |db|
        db.busy_timeout = 5000
        db.execute('PRAGMA foreign_keys = ON')
        db.execute_batch(SCHEMA)
        add_missing_columns(db)
      end
    end

    def start_run(command, user)
      prune
      db.execute(
        'INSERT INTO runs (started_at, command, user) VALUES (?, ?, ?)',
        [now, command, user]
      )
      @run_id = db.last_insert_row_id
    end

    def finish_run(status:, summary: nil, detail: nil)
      return unless @run_id

      db.execute(
        'UPDATE runs SET finished_at = ?, status = ?, summary = ?, detail = ? WHERE id = ?',
        [now, status, summary, detail, @run_id]
      )
    end

    def record_request(method:, url:, context: nil, attempt: 1, status: nil, duration_ms: nil,
                       request_body: nil, response_body: nil, error: nil)
      start_run('unknown', nil) unless @run_id

      db.execute(
        'INSERT INTO requests (run_id, created_at, context, method, url, attempt, status, ' \
        'duration_ms, request_body, response_body, error) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [@run_id, now, context, method.to_s.upcase, url, attempt, status, duration_ms,
         request_body, response_body, error]
      )
    end

    def replace_bookings(rows)
      refreshed_at = now

      db.transaction do
        db.execute('DELETE FROM bookings')
        rows.each do |row|
          db.execute(
            'INSERT INTO bookings (id, start_time, end_time, court, checked_in, refreshed_at) ' \
            'VALUES (?, ?, ?, ?, ?, ?)',
            [row[:id].to_s, row[:start_time], row[:end_time], row[:court], row[:checked_in] ? 1 : 0, refreshed_at]
          )
        end
      end
    end

    private

    def add_missing_columns(db)
      columns = db.execute('PRAGMA table_info(runs)').map { |col| col[1] }
      db.execute('ALTER TABLE runs ADD COLUMN detail TEXT') unless columns.include?('detail')
    end

    def now
      Time.now.utc.iso8601
    end

    def prune
      cutoff = (Time.now.utc - (RETENTION_DAYS * 24 * 60 * 60)).iso8601
      db.execute('DELETE FROM runs WHERE started_at < ?', [cutoff])
    end
  end
end
