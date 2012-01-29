require 'rubygems'
require 'sqlite3'
require 'date'
require 'fileutils'
require 'yaml'
require 'erb'

module RssReader
	def update_pages(config_path, db_path)
		now_datetime = DateTime.now
		
		output_dir = YAML.load(File.read(config_path))["output_dir"]

		pages_datas = [
			["1", now_datetime - Rational(1, 24), now_datetime],
			["6", now_datetime - Rational(6, 24), now_datetime - Rational(1, 24)],
			["12", now_datetime - Rational(12, 24), now_datetime - Rational(6, 24)],
			["24", now_datetime - Rational(24, 24), now_datetime - Rational(12, 24)]
		]

		index_erb = ERB.new(File.read("template/index.erb"), nil, "%")
		feeds_erb = ERB.new(File.read("template/feeds.erb"), nil, "%")

		rss_db = SQLite3::Database.new(db_path)
		rss_db.results_as_hash = true
		select_sql = "select feed_url, feed_title, update_date, title, link, content from rss where update_date between ? and ? and content_date between ? and ? order by update_date desc, feed_url"
		page_feed_nums = []

		FileUtils.mkdir_p(output_dir)
		FileUtils.rm(Dir.glob("#{output_dir}/*"))

		pages_datas.each do |page_data|
			rows = rss_db.execute(select_sql, [page_data[1].strftime("%Y-%m-%d %H:%M:%S"), page_data[2].strftime("%Y-%m-%d %H:%M:%S"),
				(now_datetime - Rational(72, 24)).strftime("%Y-%m-%d %H:%M:%S"), now_datetime.strftime("%Y-%m-%d %H:%M:%S")])
			page_feed_nums << rows.size
			slices = rows.each_slice(30).to_a
			if slices.size == 0
				slices << []
			end
			slices.each_with_index do |feeds, index|
				is_last_page = (slices.size == index + 1)
				File.open("#{output_dir}/#{page_data[0]}-#{index}.html", "w") do |file|
					file.write(feeds_erb.result(binding))
				end
			end
		end

		File.open("#{output_dir}/index.html", "w") do |file|
			file.write(index_erb.result(binding))
		end

		FileUtils.cp("template/main.css", "#{output_dir}/main.css")
	end
	
	module_function :update_pages
end

if __FILE__ == $0
	RssReader.update_pages("config.yaml", "rss.db")
end
