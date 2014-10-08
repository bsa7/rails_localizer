#- Читает файл в строку ----------------------------------------------------------------------------------------
def file2str(filename)
	file_content = ""
	File.open(filename, "r:UTF-8") do |file|
		file_content = file.read
	end
	file_content
end

#- Делает замены в строке файла по указанному методу -----------------------------------------------------------
def make_replace str_original, phrase, key, method, filename
	str = str_original
	if method == "[1]" #фраза в одинарных кавычках
		str.gsub!(Regexp.new("'[^']*?#{phrase}[^']*?'"), "I18n.t(\"#{key}\")")
	elsif method == "[2]" #фраза в двойных кавычках
		str.gsub!(Regexp.new("\"[^\"]*?#{phrase}[^\"]*?\""), "I18n.t(\"#{key}\")")
	elsif method == "[3]" #Фраза в контексте, которую меняем на вычисляемое выражение внутри строки
		str.gsub!(phrase, "\#\{I18n.t(\"#{key}\")\}")
	end
	str
end

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

