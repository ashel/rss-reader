require "update_db.rb"
require "update_pages.rb"

config_path = "config.yaml"
db_path = "rss.db"

RssReader.update_db(config_path, db_path)
RssReader.update_pages(config_path, db_path)
