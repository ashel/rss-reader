# rss-reader

livedoor Reader lite-like rss reader.

## how to use

First, copy **config_example.yaml** to **config.yaml** and edit. Parameters are:

  * **output_dir** - A directory to output generated static htmls.
  * **exclude_title_regexp** - When feed title matchs this regexp pattern, it isn't shown.
  * **feeds** - Array of feeds. This Application uses **url** only. **name** is for readability.

Next, run **update_all.rb** to generate static htmls and open index.html.
Automate running update_all.rb with auto-exec like cron.

## dependency

This application needs these gems.

  * sqlite3-ruby

## licence

This application is distributed with [MIT license](http://www.opensource.org/licenses/mit-license.php).
