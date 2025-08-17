#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'optparse'
require 'fileutils'
require 'time'

class NotesArchiver
  def initialize
    @resources_dir = 'resources'
    @output_file = 'notes_archive.csv'
    @row_limit = 1000  # Default row limit per file
    @file_cap = nil    # Default: no cap on number of files
  end

  def run
    options = parse_options
    json_files = get_json_files(options[:file])

    if json_files.empty?
      puts "No JSON files found to process."
      return
    end

    # Apply file cap if specified
    if @file_cap && json_files.length > @file_cap
      puts "Capping to #{@file_cap} files (out of #{json_files.length} total)"
      json_files = json_files.first(@file_cap)
    end

    puts "Processing #{json_files.length} JSON file(s)..."
    puts "Row limit per file: #{@row_limit}"
    process_files_with_limit(json_files)
    puts "CSV files created successfully!"
  end

  private

  def parse_options
    options = {}

    OptionParser.new do |opts|
      opts.banner = "Usage: ruby notes-archiver.rb [options]"

      opts.on("-f", "--file FILENAME", "Process specific JSON file from resources directory") do |file|
        options[:file] = file
      end

      opts.on("-o", "--output FILENAME", "Output CSV filename (default: notes_archive.csv)") do |output|
        @output_file = output
      end

      opts.on("-l", "--limit ROWS", Integer, "Row limit per file (default: 1000)") do |limit|
        @row_limit = limit
      end

      opts.on("-c", "--cap FILES", Integer, "Maximum number of JSON files to process") do |cap|
        @file_cap = cap
      end

      opts.on("-h", "--help", "Show this help message") do
        puts opts
        exit
      end
    end.parse!

    options
  end

  def get_json_files(specific_file = nil)
    if specific_file
      file_path = File.join(@resources_dir, specific_file)
      if File.exist?(file_path) && file_path.end_with?('.json')
        [file_path]
      else
        puts "Error: File '#{specific_file}' not found or not a JSON file in resources directory."
        []
      end
    else
      Dir.glob(File.join(@resources_dir, '*.json'))
    end
  end

  def process_files_with_limit(json_files)
    csv_data = []
    file_counter = 1
    row_counter = 0

    json_files.each do |file_path|
      begin
        puts "Processing: #{File.basename(file_path)}"
        json_content = File.read(file_path)
        note_data = JSON.parse(json_content)

        # Convert note to CSV row(s)
        rows = convert_note_to_csv_rows(note_data, File.basename(file_path))

        rows.each do |row|
          csv_data << row
          row_counter += 1

          # Check if we've reached the row limit
          if row_counter >= @row_limit
            write_csv_file(csv_data, file_counter)
            csv_data = []
            row_counter = 0
            file_counter += 1
          end
        end

      rescue JSON::ParserError => e
        puts "Error parsing JSON in #{File.basename(file_path)}: #{e.message}"
      rescue => e
        puts "Error processing #{File.basename(file_path)}: #{e.message}"
      end
    end

    # Write remaining data to final file
    if !csv_data.empty?
      write_csv_file(csv_data, file_counter)
    end
  end

  def write_csv_file(csv_data, file_number)
    return if csv_data.empty?

    # Generate filename with number suffix
    base_name = @output_file.sub(/\.csv$/, '')
    filename = file_number == 1 ? "#{base_name}.csv" : "#{base_name}_#{file_number}.csv"

    CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      # Write headers
      csv << csv_data.first.keys

      # Write data rows
      csv_data.each do |row|
        csv << row.values
      end
    end

    puts "Created: #{filename} (#{csv_data.length} rows)"
  end

  def convert_note_to_csv_rows(note_data, filename)
    # Always create a single row per note
    row = create_base_row(note_data, filename)
    [row]
  end

  def create_base_row(note_data, filename)
    {
      'filename' => filename,
      'color' => note_data['color'] || '',
      'isTrashed' => note_data['isTrashed'] || false,
      'isPinned' => note_data['isPinned'] || false,
      'isArchived' => note_data['isArchived'] || false,
      'title' => note_data['title'] || '',
      'textContent' => note_data['textContent'] || '',
      'userEditedTimestampUsec' => note_data['userEditedTimestampUsec'] || '',
      'userEditedTimestampISO' => convert_timestamp_to_iso(note_data['userEditedTimestampUsec']),
      'createdTimestampUsec' => note_data['createdTimestampUsec'] || '',
      'createdTimestampISO' => convert_timestamp_to_iso(note_data['createdTimestampUsec']),
      'textContentHtml' => note_data['textContentHtml'] || '',
      'labels' => extract_labels(note_data['labels']),
      'annotations' => extract_annotations(note_data['annotations'])
    }
  end

  def convert_timestamp_to_iso(timestamp_usec)
    return '' unless timestamp_usec && timestamp_usec.to_s.match?(/^\d+$/)

    # Convert microseconds to seconds
    timestamp_sec = timestamp_usec.to_i / 1_000_000

    # Convert to ISO 8601 format
    Time.at(timestamp_sec).utc.iso8601
  rescue => e
    # Return empty string if conversion fails
    ''
  end

  def extract_annotations(annotations)
    return '[]' unless annotations && annotations.is_a?(Array)

    annotations.map do |annotation|
      {
        'description' => annotation['description'] || '',
        'source' => annotation['source'] || '',
        'title' => annotation['title'] || '',
        'url' => annotation['url'] || ''
      }
    end.to_json
  end

  def convert_annotation_to_row(annotation, index)
    {
      'annotation_description' => annotation['description'] || '',
      'annotation_source' => annotation['source'] || '',
      'annotation_title' => annotation['title'] || '',
      'annotation_url' => annotation['url'] || ''
    }
  end

  def extract_labels(labels)
    return '[]' unless labels && labels.is_a?(Array)
    labels.map { |label| label['name'] }.to_json
  end


end

# Run the program
if __FILE__ == $0
  archiver = NotesArchiver.new
  archiver.run
end
