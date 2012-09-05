require "json"

module Translate
  class Translation
    def initialize(input)
      @input = input
      @table = nil
      @columns = nil
      @rows = nil
    end

    def from_mysql
      parse_mysql
      self
    end

    def to_html
      html = "<table><tr class=\"header-row\">" + @columns.map { |header| "<th>#{header}</th>" }.join + "</tr>"
      @rows.each do |row|
        html << "<tr>" + row.map { |value| "<td>#{value}</td>" }.join + "</tr>"
      end
      html << "</table>"
    end

    def to_json
      records = []
      @rows.each do |row|
        record = {}
        row.each_with_index do |cell, i|
          record[@columns[i]] = cell
        end
        records << record
      end
      "<pre>#{JSON.pretty_generate(records)}</pre>"
    end

    def to_ruby
      ruby = "["
      @rows.each_with_index do |row, i|
        ruby << "," if i > 0
        ruby << "\n  {"
        row.each_with_index.each do |cell, j|
          key = @columns[j].gsub(/[^\w]/, "_")
          value = cell.gsub('"', '\"')
          ruby << "," if j > 0
          ruby << "\n    :#{key} => \"#{value}\""
        end
        ruby << "\n  }"
        ruby << "\n" if i == (@rows.count - 1)
      end
      ruby << "]"
      "<pre>#{ruby}</pre>"
    end

    private
    def parse_mysql
      @table = []
      @input.lines.each_with_index do |line, index|
        next if line.match(/^[\+\-]*$/) # Skip pure border lines.
        @table << line.split("|").map(&:strip).reject(&:empty?)
      end
      @columns = @table.first || []
      @rows = @table[1..-1] || []
    end
  end

  def self.table(input)
    Translation.new(input)
  end
end
