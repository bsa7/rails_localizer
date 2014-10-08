require 'colorize'
require 'unicode'
require 'yaml'
require './common'

files = YAML.load_file('settings.yml')

#Dir.pwd.red
files.each do |filename, phrases|
	file_strings = file2str(filename).split(/\n/)
	puts "will replace in file #{filename}"
	phrases.each do |phrase_index, phrase_settings|
		puts "  строка #{phrase_settings['номер_строки']}: #{phrase_settings['оригинальная_строка_файла']}"
		puts "  тест строка из файла: #{file_strings[phrase_settings['номер_строки']]}"
		str_original = file_strings[phrase_settings['номер_строки']]
		file_strings[phrase_settings['номер_строки']] = make_replace(str_original.clone, phrase_settings['оригинал_фразы'], phrase_settings["ключ_фразы"], phrase_settings["действие"], filename)
		puts "  тест строка станет: #{file_strings[phrase_settings['номер_строки']]}"
	end
end
