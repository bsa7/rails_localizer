require 'fileutils'
require 'colorize'
require 'unicode'
require 'yaml'
require './common'

files = YAML.load_file('settings.yml')
current_localization = YAML.load_file('../config/locales/ru.yml')

new_locale_settings = {}

files.each do |filename, phrases|
	file_strings = file2str(filename).split(/\n/)
	phrases.each do |phrase_index, phrase_settings|
		str_original = file_strings[phrase_settings['номер_строки']]
		phrase_key = phrase_settings["ключ_фразы"]
		phrase_value = phrase_settings["новая_версия_фразы"]
		replace_mode = phrase_settings['действие'][/\d+/]
		if replace_mode #работаем со всеми действиями, кроме '[]'
			puts "#{filename} - [#{replace_mode}] - phrase_key: #{phrase_key}, phrase_value: #{phrase_value}"
			file_strings[phrase_settings['номер_строки']] = phrase_settings['какой_строка_файла__будет'] #Значения для подстановки берём из файла настроек
			arr = phrase_key.split('.')
			if arr.size > 1
				phrase_namespace = arr[0]
				phrase_key = arr[1]
				new_locale_settings[phrase_namespace] ||= {}
				new_locale_settings[phrase_namespace][phrase_key] = phrase_value
			else
				phrase_namespace = nil
				new_locale_settings[phrase_key] = phrase_value
			end
		end
	end
	File.open(filename, "w") do |source_file|
		file_strings.each do |str|
			source_file.write "#{str}\n"
		end
	end
end

new_localization ||= {}
new_localization["ru"] = current_localization["ru"].merge new_locale_settings

#FileUtils.cp("../config/locales/ru.yml", "../config/locales/ru_#{Time.now.strftime('%Y%m%d%H%M%S').to_i}.yml")
File.open("../config/locales/ru.yml", "w") do |new_localization_file|
	new_localization_file.write new_localization.to_yaml(line_width: 500)
end
