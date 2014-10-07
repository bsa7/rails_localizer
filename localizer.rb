require 'unicode'
require 'colorize'

#- Common unicode string helpers --------------------------------------- 
class String

	def words_str
		self.split(/[^a-zA-Zа-яА-ЯёЁ0-9]/).reject(&:empty?).join(' ')
	end

	def first_n_words n
		text = self.clone
		words = text.scan(/[a-zA-Zа-яёА-ЯЁ]+/)[0..n-1]
		if words.size < n
			res = text
		else
			res = words.each_with_object([]){|k,v|t= text.index k; v << text[0..t+k.size-1]; text = text[t+k.size..-1]}.join
		end
		res
	end

	def last_n_words n
		text = self.clone
		words = text.scan(/[a-zA-Zа-яёА-ЯЁ]+/)[-n..-1]
		if words.size < n
			res = text
		else
			res = words.each_with_object([]){|k,v|t= text.index k; v << text[0..t+k.size-1]; text = text[t+k.size..-1]}.join
		end
		res
	end

	def word_count
		self.split(/[^a-zA-Zа-яА-ЯёЁ0-9]/).reject(&:empty?).size
	end

	def unquote
		self.gsub(/\"|\'/,"")
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
		/(([а-яА-ЯёЁ]+[\,\.\s–\-:;><\)\(\&a-zA-Z]*)++)/
	]
end

#- Разбор Ruby файла -------------------------------------------------------------------------------------------
def localize(filename, template_numbers)
	file_content = file2str filename
	template_numbers.each do |template_number|
		create_dictionary(filename, file_content, phrases_templates[template_number])
	end
end

#- обновление / создание словаря из встреченных в файле по регулярному выражению -------------------------------
def create_dictionary(filename, file_content, regexp)
	first_n = 4
	last_m = 2
	namespace = filename.split('/')[1].split(/[_\.]/)[0]
	file_strings = file_content.split(/\n/)
	file_strings.each do |str|
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
					words_array = phrase.split(/[^a-zA-Zа-яА-ЯёЁ0-9]/).reject(&:empty?)
					phrase = words_array[0..first_n-1].join(' ')+"  "+words_array[-last_m..-1].join(' ')
				else
					phrase = phrase.words_str
				end
				puts "#{filename} - ".yellow + "#{namespace}.#{phrase.downcase.gsub(/[^а-яА-ЯёЁa-zA-Z0-9]/,'_')}".cyan
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

#----------------------------------------------------------------------- 
Dir.glob("**/*").each do |entryname|
	if File.directory? entryname
		next
	elsif entryname == 'localizer.rb'
		next
	elsif entryname.split('/')[0..1].include? "admin"
		next
	end
	if entryname =~ /\.rb$/i
		localize entryname, [0]
	elsif entryname =~ /\.haml$/i
		localize entryname, [0]
	end
end

