require "haml"
require "sinatra"

require File.join(File.dirname(__FILE__), "lib", "translate")

get "/" do
  haml :index
end

post "/" do
  translation = Translate.table(params["input"])

  case params["input-format"]
  when "mysql"
    translation.from_mysql
  else
    translation.from_mysql
  end

  case params["output-format"]
  when "csv"
    "<pre>#{translation.to_csv}</pre>"
  when "html"
    translation.to_html
  when "json"
    "<pre>#{translation.to_json}</pre>"
  when "ruby"
    "<pre>#{translation.to_ruby}</pre>"
  else
    translation.to_html
  end
end
