# notes-archiver

Notes exported from Google Keep, by Google Takeout, which outputs html and json files, this tool can build up a CSV database that you can import into other note taking apps.

## How to run:
```
Process all JSON files in resources directory

ruby notes-archiver.rb

Process a specific file

ruby notes-archiver.rb --file "yamaha tenere pictures.json"

Process a specific file with custom output

ruby notes-archiver.rb --file "Color themes for iTerm2.json" --output "my_output.csv"

Show help

ruby notes-archiver.rb --help
```

## How to run 2:

```
Usage: ruby notes-archiver.rb [options]
    -f, --file FILENAME              Process specific JSON file from resources directory
    -o, --output FILENAME            Output CSV filename (default: notes_archive.csv)
    -h, --help                       Show this help message
```
