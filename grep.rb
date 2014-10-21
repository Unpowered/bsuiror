#!/home/andrew/.rvm/gems/ruby-2.1.3 ruby

require 'rubygems'
require 'zip'
require 'colorize'

class Grep

  def initialize (argv_data)

    @invalid_option_regexp = Regexp.new('^-(([^RzeA].*)|([RzeA].+))')

    case argv_data[0]

      when nil
        show_proper_usage

      when '--help'
        show_help

      when @invalid_option_regexp # invalid option
        invalid_option_msg (argv_data[0])

      when '-R'
        if argv_data.length < 3
          show_proper_usage
        else
          @option = '-R'
          @pattern = argv_data[1]
          @directory_path = argv_data[2..-1].to_a
        end

      when '-z'
        if argv_data.length < 3
          show_proper_usage
        else
          @option = '-z'
          @pattern = argv_data[1]
          @zip_path = argv_data[2..-1].to_a
        end

      when '-e'
        if argv_data.length < 3
          show_proper_usage
        else
          @option = '-e'
          @pattern_regexp = Regexp.new(argv_data[1])
          @file_path = argv_data[2..-1].to_a
        end

      when '-A'
        if argv_data.length < 4
          show_proper_usage
        else
          @option = '-A'
          @strings_around = number_from_string(argv_data[1])
          @pattern = argv_data[2]
          @file_path = argv_data[3..-1].to_a
        end

      else 
        if argv_data.length == 1
          @option = '-i' # input
          @pattern = argv_data[0]
        else
          @option = '-f' # PATTERN
          @pattern = argv_data[0]
          @file_path = argv_data[1..-1].to_a
        end

    end
  end

  def run
    case @option

      when '-R'
        @directory_path.each do |directorypath|
          @dir = try_directory (directorypath)
          if !@dir
            next
          end
          Dir.foreach(directorypath) do |filename|
            if ( filename[0] != '.' && filename[-1] != '~' && File.file?(filename) )
              @file = File.open (filename)
              @file.each do |line|
                if line.include?@pattern
                  print (directorypath + '/' + filename).blue + ': ' + (line.gsub @pattern, @pattern.red)
                end
              end
              @file.close
            end
          end
        end

      when '-z'
        @zip_path.each do |zippath|
          @zip = try_zip (zippath)
          if !@zip
            next
          end
          Zip::File.open(zippath) do |zipname|
            zipname.each do |file|
              file.extract(file.name)
              file.get_input_stream.read.each_line do |line|
                if line.include?@pattern
                  print (zippath + '/' + file.name).blue + ': ' + (line.gsub @pattern, @pattern.red)
                end
              end
              File.delete(file.name)
            end
          end
        end

      when '-e'
        @file_path.each do |filepath|
          @file = try_file (filepath)
          if !@file
            next
          end 
          @file.each do |line|
            if @pattern_regexp.match(line)
              print filepath.blue + ': ' + (line.gsub line[@pattern_regexp], line[@pattern_regexp].red)
            end
          end
          @file.close
        end

      when '-A'
        @file_path.each do |filepath|
          @file_as_array = Array.new
          @file = try_file (filepath)
          if !@file
            next
          end
          @file.each do |line|
            @file_as_array << line
          end
          @file.close
          @file_as_array.each_index do |i|
            if @file_as_array[i].include?@pattern
              @first_string_index = i-@strings_around < 0 ? 0 : i-@strings_around
              @last_string_index = i+@strings_around > @file_as_array.length-1 ? @file_as_array.length-1 : i+@strings_around
              @file_as_array[@first_string_index..@last_string_index].each do |line|
                print filepath.blue + ': ' + (line.gsub @pattern, @pattern.red)
              end
              puts '----------------------------------------------------------------'
            end
          end
        end

      when '-i'
        ARGV.clear
        while true do
          @string = gets.chomp
          if @string == '#q'
            exit
          end
          if @string.include?@pattern
            puts @string.gsub @pattern, @pattern.red
          end
        end

      when '-f'
        @file_path.each do |filepath|
          @file = try_file (filepath)
          if !@file
            next
          end
          @file.each do |line|
            if line.include?@pattern
              print filepath.blue + ': ' + (line.gsub @pattern, @pattern.red)
            end
          end
          @file.close
        end

    end
  end

  def try_file (file_path)
    if File.exist?(file_path) && File.file?(file_path)
      file = File.open (file_path)
      return file
    else
      puts "grep: #{file_path}: No such file"
      return false
    end
  end

  def try_directory (directory_path)
    if Dir.exist?(directory_path)
      return true
    else
      puts "grep: #{directory_path}: No such directory"
      return false
    end
  end

  def try_zip (zip_path)
    if File.exist?(zip_path) && File.file?(zip_path)
      return true
    else
      puts "grep: #{zip_path}: No such archive"
      return false
    end
  end

  def show_proper_usage
    puts "USAGE: ./grep.rb [OPTION] [OPTION_ARGUMENT] PATTERN [FILE]..."
    puts "Try \'./grep.rb --help\' for more information."
    exit
  end

  def show_help
    puts "USAGE: ./grep.rb [OPTION] [OPTION_ARGUMENT] PATTERN [FILE]..."
    puts "Search for PATTERN in each FILE or standard input."
    puts "PATTERN is, by default, a string."
    puts "Example: ./grep.rb 'hello world' menu.h main.c\n\n"
    puts "Available OPTIONS:"
    puts "  -R       search PATTERN in all the files of directory"
    puts "  -z       search PATTERN in all the files extracted from archive"
    puts "  -e       PATTERN is Regexp"
    puts "  -A  NUM  print NUM lines of leading and trailing context, NUM>=0"        
    exit
  end

  def invalid_option_argument_msg
    puts "WRONG [OPTION_ARGUMENT]"
    puts "Try \'./grep.rb --help\' for more information."
    exit
  end

  def invalid_option_msg (option)
    puts "grep: invalid option \'#{option[0..-1]}\'"
    show_proper_usage
  end

  def number_from_string(string)
    begin
    number = Integer(string)
    rescue Exception
    invalid_option_argument_msg
    exit
    else
      if number < 0
        invalid_option_argument_msg
        exit
      else
        return number
      end
    end
  end

end

grep = Grep.new (ARGV)
grep.run