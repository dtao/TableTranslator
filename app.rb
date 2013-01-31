require "haml"
require "sinatra"

require File.join(File.dirname(__FILE__), "lib", "translate")

helpers do
  def param_checked?(param)
    ["1", "true"].any? { |val| params[param].to_s == val }
  end
end

get "/" do
  haml :index
end

post "/" do
  translation = Translate.table(params["input"])

  case params["input-format"]
  when "mysql"
    translation.from_mysql
  when "html"
    translation.from_html
  when "tsv"
    translation.from_delimited("\t")
  when "yaml"
    translation.from_yaml
  else
    translation.from_mysql
  end

  if param_checked?("parse-numbers")
    translation.parse_numbers
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
  when "tsv"
    "<pre>#{translation.to_tsv}</pre>"
  when "yaml"
    "<pre>#{translation.to_yaml}</pre>"
  else
    translation.to_html
  end
end
