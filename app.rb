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
  else
    translation.from_mysql
  end

  case params["output-format"]
  when "html"
  else
    translation.to_html
  end
end
