#!/usr/bin/env ruby

require 'json'
require 'csv'
require 'optparse'
require 'fileutils'

class NotesArchiver
  def initialize
    @resources_dir = 'resources'
    @output_file = 'notes_archive.csv'
  end

  def run
    options = parse_options
    json_files = get_json_files(options[:file])

    if json_files.empty?
      puts "No JSON files found to process."
      return
    end

    puts "Processing #{json_files.length} JSON file(s)..."
    csv_data = process_files(json_files)
    write_csv(csv_data)
    puts "CSV file created: #{@output_file}"
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

  def process_files(json_files)
    csv_data = []
    headers_written = false

    json_files.each do |file_path|
      begin
        puts "Processing: #{File.basename(file_path)}"
        json_content = File.read(file_path)
        note_data = JSON.parse(json_content)

        # Convert note to CSV row(s)
        rows = convert_note_to_csv_rows(note_data, File.basename(file_path))

        csv_data.concat(rows)

        # Write headers only once
        unless headers_written
          headers = rows.first.keys
          headers_written = true
        end

      rescue JSON::ParserError => e
        puts "Error parsing JSON in #{File.basename(file_path)}: #{e.message}"
      rescue => e
        puts "Error processing #{File.basename(file_path)}: #{e.message}"
      end
    end

    csv_data
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
      'createdTimestampUsec' => note_data['createdTimestampUsec'] || '',
      'textContentHtml' => note_data['textContentHtml'] || '',
      'labels' => extract_labels(note_data['labels']),
      'annotations' => extract_annotations(note_data['annotations'])
    }
  end

  def extract_annotations(annotations)
    return '' unless annotations && annotations.is_a?(Array)

    annotations.map do |annotation|
      parts = []
      parts << annotation['description'] if annotation['description'] && !annotation['description'].empty?
      parts << annotation['source'] if annotation['source'] && !annotation['source'].empty?
      parts << annotation['title'] if annotation['title'] && !annotation['title'].empty?
      parts << annotation['url'] if annotation['url'] && !annotation['url'].empty?

      parts.join(' | ')
    end.join('; ')
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
    return '' unless labels && labels.is_a?(Array)
    labels.map { |label| label['name'] }.join('; ')
  end

  def write_csv(csv_data)
    return if csv_data.empty?

    CSV.open(@output_file, 'w', encoding: 'UTF-8') do |csv|
      # Write headers
      csv << csv_data.first.keys

      # Write data rows
      csv_data.each do |row|
        csv << row.values
      end
    end
  end
end

# Run the program
if __FILE__ == $0
  archiver = NotesArchiver.new
  archiver.run
end
