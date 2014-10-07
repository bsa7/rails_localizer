require 'unicode'
require 'colorize'

#- Common unicode string helpers --------------------------------------- 
class String

	def words_array
		self.split(/[^a-zA-Zа-яА-ЯёЁ0-9]/).reject(&:empty?)
	end

	def words_str
		self.words_array.join(' ')
	end

	def word_count
		self.words_array.size
	end

	def downcase
		Unicode::downcase(self)
	end

	def downcase!
		self.replace downcase
	end

	def upcase
		Unicode::upcase(self)
	end

	def upcase!
		self.replace upcase
	end

	def capitalize
		Unicode::capitalize(self)
	end

	def capitalize!
		self.replace capitalize
	end

end

#- Разбор Ruby файла -------------------------------------------------------------------------------------------
def phrases_templates
	[
		/(([а-яА-ЯёЁ]+[\!\?\,\.\s–\-:;><\)\(\&a-zA-Z]*)++)/
	]
end

#- Разбор Ruby файла -------------------------------------------------------------------------------------------
def localize(filename, template_numbers, settings_file)
	file_content = file2str filename
	template_numbers.each do |template_number|
		create_dictionary(filename, file_content, phrases_templates[template_number], settings_file)
	end
end

#- обновление / создание словаря из встреченных в файле по регулярному выражению -------------------------------
def create_dictionary(filename, file_content, regexp, settings_file)
	first_n = 4
	last_m = 2
	namespace = filename.split('/')[1].split(/[_\.]/)[0]
	file_strings = file_content.split(/\n/)
	file_strings.each_with_index do |str_original, str_number|
		str = str_original.clone
		if filename =~ /\.rb$/
			str.gsub!(/#[^{].+$/,'') #Вырезаем комментарии
		elsif filename =~ /\.haml$/
			str.gsub!(/^\s*\/.+$/,'') #Вырезаем комментарии
			str.gsub!(/^\s*-\s*#.+$/,'') #Вырезаем комментарии
		end
		if str =~ regexp
			result = str.scan(regexp)
#			puts result.inspect.magenta
#			puts str.yellow
			result.each do |arr|
				phrase = arr[0]
				if phrase.word_count > first_n + last_m
					words_array = phrase.words_array
					phrase = words_array[0..first_n-1].join(' ')+"  "+words_array[-last_m..-1].join(' ')
				else
					phrase = phrase.words_str
				end
				puts "#{filename} - ".yellow + "#{namespace}.#{phrase.downcase.gsub(/[^а-яА-ЯёЁa-zA-Z0-9]/,'_')}".cyan
				settings_file.write "[]#{namespace}.#{phrase.downcase.gsub(/[^а-яА-ЯёЁa-zA-Z0-9]/,'_')} <delimiter> ##{str_number}#{str_original} <delimiter> #{filename}\n"
			end
		end
	end
end

#- Читает файл в строку ----------------------------------------------------------------------------------------
def file2str(filename)
	file_content = ""
	File.open(filename, "r:UTF-8") do |file|
		file_content = file.read
	end
	file_content
end

def settings_message
	"
		# Конфигурационный файл подготовки Rails-проекта к интернационализации
		# Этап 1. Настройка
		#  В нижеследующих строках установите в началах строк флаги по следующему принципу:
		#  [x] - Не изменять текущую фразу
		#  [x] - 
		#  [x] - 
	"
end

#-----------------------------------------------------------------------
File.open("settings.yml", "w") do |settings_file|
	settings_file.write "#{settings_message}\n\n" 
	Dir.glob("**/*").each do |entryname|
		if File.directory? entryname
			next
		elsif entryname =~ /localizer.+?\.rb$/
			next
		elsif entryname.split('/')[0..1].include? "admin"
			next
		end
		if entryname =~ /\.rb$/i
			localize entryname, [0], settings_file
		elsif entryname =~ /\.haml$/i
			localize entryname, [0], settings_file
		end
	end
end

