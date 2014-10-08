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

