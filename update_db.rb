require 'rubygems'
require 'sqlite3'
require 'rss'
require 'open-uri'
require 'date'
require 'yaml'

module RssReader
	def create_rss_table(db)
		sql = <<EOS
create table rss (
	id integer,
	feed_url text,
	feed_title text,
	content_date text,
	update_date text,
	title text,
	link text,
	content text,
	primary key(id)
);
EOS
		db.execute(sql)
	end
	
	def create_lastmodified_table(db)
		sql = <<EOS
create table lastmodified (
	id integer,
	feed_url text,
	date text,
	primary key(id)
);
EOS
		db.execute(sql)
	end
	
	def update_db(config_path, db_path)
		insert_sql = "insert into rss(feed_url, feed_title, content_date, update_date, title, link, content) values(?, ?, ?, ?, ?, ?, ?)"
		select_sql = "select id from rss where link = ?"
		select_lastmodified_sql = "select id, date from lastmodified where feed_url = ?"
		update_lastmodified_sql = "update lastmodified set date = ? where id = ?"
		insert_lastmodified_sql = "insert into lastmodified(feed_url, date) values(?, ?)"
		
		config = YAML.load(File.read(config_path))
		exclude_title_regexp = Regexp.new(config["exclude_title_regexp"])
		feeds = config["feeds"]
		
		is_rss_db_exist = File.exist?(db_path)
		rss_db = SQLite3::Database.new(db_path)
		rss_db.results_as_hash = true
		unless is_rss_db_exist
			create_rss_table(rss_db)
			create_lastmodified_table(rss_db)
		end
		
		now_datetime = DateTime.now.strftime("%Y-%m-%d %H:%M:%S")

		feeds.each do |feed|
			puts "update #{feed["url"]}"
			str = nil
			
			get_option = {'User-Agent' => "Ruby/#{RUBY_VERSION}"}
			lastmodified_id = nil
			rss_db.execute(select_lastmodified_sql, feed["url"]) do |row|
				lastmodified_id = row['id']
				get_option['If-Modified-Since'] = Time.parse(row['date']).httpdate
			end
			
			begin
				open(feed["url"], get_option) do |file|
					str = file.read
					if file.last_modified
						if lastmodified_id
							rss_db.execute(update_lastmodified_sql, [file.last_modified.strftime("%Y-%m-%d %H:%M:%S"), lastmodified_id])
						else
							rss_db.execute(insert_lastmodified_sql, [feed["url"], file.last_modified.strftime("%Y-%m-%d %H:%M:%S")])
						end
					end
				end
			rescue OpenURI::HTTPError => e
				p e
				next
			end

			begin
				rss = RSS::Parser.parse(str)
			rescue StandardError => e
				p e
				next
			end

			rss_title = rss.channel.title.to_s

			rss_db.transaction do
				rss.items.each do |item|
					ret = rss_db.execute(select_sql, item.link)
					if ret.size == 0 && exclude_title_regexp !~ item.title
						content_datetime = DateTime.parse((item.dc_date || item.pubDate).to_s).strftime("%Y-%m-%d %H:%M:%S")
						rss_db.execute(insert_sql, [feed["url"], rss_title, content_datetime, now_datetime, item.title, item.link, item.content_encoded || item.description])
					end
				end
			end
		end
	end
	
	module_function :create_rss_table, :update_db
end

if __FILE__ == $0
	RssReader.update_db("config.yaml", "rss.db")
end
