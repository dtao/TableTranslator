require "json"
require "nokogiri"
require "safe_yaml"

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

    def from_delimited(delimiter)
      parse_delimited(delimiter)
      self
    end

    def from_html
      parse_html
      self
    end

    def from_yaml
      parse_yaml
      self
    end

    def parse_numbers
      @rows.each do |row|
        (0...row.length).each do |i|
          next if !row[i].is_a?(String)

          if row[i].match(/^\d+$/)
            row[i] = row[i].to_i
          elsif row[i].match(/^\d{1,3}(?:,\d{3})*$/)
            row[i] = row[i].gsub(",", "").to_i
          elsif row[i].match(/^\d*\.\d+$/)
            row[i] = row[i].to_f
          end
        end
      end
    end

    def to_csv
      ([row_to_csv(@columns)] + @rows.map { |row| row_to_csv(row) }).join("\n")
    end

    def to_html
      html = "<table><tr class=\"header-row\">" + @columns.map { |header| "<th>#{header}</th>" }.join + "</tr>"
      @rows.each do |row|
        html << "<tr>" + row.map { |value| "<td>#{value}</td>" }.join + "</tr>"
      end
      html << "</table>"
    end

    def to_json
      JSON.pretty_generate(rows_to_records)
    end

    def to_ruby
      ruby = "["

      keys = @columns.map do |column|
        column.gsub(/[^\w]/, "_").gsub("\n", "\\n")
      end

      @rows.each_with_index do |row, i|
        ruby << "," if i > 0
        ruby << "\n  {"
        row.each_with_index.each do |cell, j|
          key = keys[j]
          value = cell.is_a?(String) ? "\"#{escape(cell)}\"" : cell
          ruby << "," if j > 0
          ruby << "\n    :#{key} => #{value}"
        end
        ruby << "\n  }"
        ruby << "\n" if i == (@rows.count - 1)
      end
      ruby << "]"
      ruby
    end

    def to_yaml
      rows_to_records.to_yaml
    end

    private
    def parse_mysql
      @table = []
      @input.lines.each_with_index do |line, index|
        next if line.match(/^[\+\-]*$/) # Skip pure border lines.
        @table << line.split("|").map(&:strip).reject(&:empty?)
      end
      set_columns_and_rows()
    end

    def parse_delimited(delimiter)
      @table = []
      @input.lines.each_with_index do |line, index|
        @table << line.split(delimiter).map(&:strip)
      end
      set_columns_and_rows()
    end

    def parse_html
      @table = []
      html_doc = Nokogiri::HTML.parse(@input)
      html_doc.css("tr").each do |html_row|
        @table << html_row.css("td", "th").map(&:text).map(&:strip)
      end
      set_columns_and_rows()
    end

    def parse_yaml
      hashes = YAML.safe_load(@input)
      @columns = hashes.first.keys
      @rows = hashes.map { |hash| @columns.map { |column| hash[column] } }
    end

    def set_columns_and_rows
      @columns = @table.first || []
      @rows = @table[1..-1] || []
    end

    def rows_to_records
      records = []
      @rows.each do |row|
        record = {}
        row.each_with_index do |cell, i|
          record[@columns[i]] = cell
        end
        records << record
      end
      records
    end

    def row_to_csv(row)
      row.map { |cell| qualify(escape(cell), ',', '"') }.join(",")
    end

    def escape(text)
      if text.is_a?(String) && text.include?("\n")
        text = text.gsub(/\n/, "\\n").gsub(/"/, "\\\"")
      end

      text
    end

    def qualify(text, delimiter, qualifier)
      if text.is_a?(String) && (delimiter.nil? || text.include?(delimiter))
        text = qualifier + text.gsub(qualifier, "\\#{qualifier}") + qualifier
      end

      text
    end
  end

  def self.table(input)
    Translation.new(input)
  end
end
