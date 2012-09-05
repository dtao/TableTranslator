require "json"

module Translate
  class Translation
    def initialize(input)
      @input = input
      @table = nil
      @columns = nil
    end

    def from_mysql
      parse_mysql
      self
    end

    def to_html
      html = "<table><tr class=\"header-row\">" + @table[0].map { |header| "<th>#{header}</th>" }.join + "</tr>"
      @table[1..-1].each do |row|
        html << "<tr>" + row.map { |value| "<td>#{value}</td>" }.join + "</tr>"
      end
      html << "</table>"
    end

    def to_json
      records = []
      @table[1..-1].each do |row|
        record = {}
        row.each_with_index do |cell, i|
          record[@columns[i]] = cell
        end
        records << record
      end
      "<pre>#{JSON.pretty_generate(records)}</pre>"
    end

    private
    def parse_mysql
      @table = []
      @input.lines.each_with_index do |line, index|
        next if line.match(/^[\+\-]*$/) # Skip pure border lines.
        @table << line.split("|").map(&:strip).reject(&:empty?)
      end
      @columns = @table[0]
    end
  end

  def self.table(input)
    Translation.new(input)
  end
end
