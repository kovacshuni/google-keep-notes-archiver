# notes-archiver

Notes exported from Google Keep, by Google Takeout, which outputs html and json files, this tool can build up a CSV database that you can import into other note taking apps.

## How to run:
```
# Process all files with 2000 rows per file
ruby notes-archiver.rb --limit 2000

# Test with only 10 files, 5 rows per file
ruby notes-archiver.rb --cap 10 --limit 5 --output "test.csv"

# Process specific file with 100 rows per file
ruby notes-archiver.rb --file "large_file.json" --limit 100

# Process a specific file

ruby notes-archiver.rb --file "yamaha tenere pictures.json"

# Process a specific file with custom output

ruby notes-archiver.rb --file "Color themes for iTerm2.json" --output "my_output.csv"

# Sort by creation timestamp (newest first. Will consume memory.)

ruby notes-archiver.rb --sort

# Show help

ruby notes-archiver.rb --help
```

## How to run 2:

```
Usage: ruby notes-archiver.rb [options]
    -f, --file FILENAME              Process specific JSON file from resources directory
    -o, --output FILENAME            Output CSV filename (default: notes_archive.csv)
    -l, --limit ROWS                 Row limit per file (default: 1000)
    -c, --cap FILES                  Maximum number of JSON files to process
    -s, --sort                       Sort data by createdTimestampUsec in descending order
    -h, --help                       Show this help message
```
