require 'unicode'
require 'colorize'
require 'yaml'
require './common'

$settings = {}

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
		/(([а-яА-ЯёЁ]+[\!\?\,\._\s–\-:;><\)\\\/\(\&a-zA-Z]*)++)/
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
			result.each do |arr|
				phrase = arr[0].strip
				if phrase.word_count > first_n + last_m
					words_array = phrase.words_array
					phrase = words_array[0..first_n-1].join(' ')+"  "+words_array[-last_m..-1].join(' ')
				else
					phrase = phrase.words_str
				end
				filename_str = filename
				$settings[filename_str] ||= {}
				position = $settings[filename_str].keys.size+1
				new_episode = {}
				new_episode["номер_строки"] = str_number
				new_episode["ключ_фразы"] = "#{namespace}.#{phrase.downcase.gsub(/[^а-яА-ЯёЁa-zA-Z0-9]/,'_')}"
				new_episode["оригинал_фразы"] = arr[0].strip
				new_episode["новая_версия_фразы"] = arr[0].strip
				new_episode["оригинальная_строка_файла"] = str_original
				new_episode["действие"] = "[#{guess_context(arr[0].strip, str_original, filename)}]"
				new_episode["какой_строка_файла__будет"] = make_replace(str, arr[0].strip, new_episode["ключ_фразы"], new_episode["действие"], filename)
				$settings[filename_str]["#{position}"] = new_episode
			end
		end
	end
end

#- Пытается угадать контекст, в котором найдена фраза. Если не может - возвращает пустое значение --------------
def guess_context(phrase, str, filename)
	if phrase[/[\s\.\,\~\&\:\;\(\)\[\]\{\}\-\+\=\_]/] != nil
		arr = str.split(phrase)
	else
		arr = str.split(Regexp.new("\\b#{phrase}\\b"))
	end
	method = ""
	if arr.size == 2 || arr.size == 1 #Простой случай, такая фраза в строке уникальна
		if arr[0][-1].strip == "'" && (arr[1] && arr[1][0].strip == "'" || !arr[1])
			method = "1"
		elsif arr[0][-1].strip == "\"" && (arr[1] && arr[1][0].strip == "\"" || !arr[1])
			method = "2"
		elsif arr[0].scan("\#\{").size > arr[0].scan("\}").size
			method = ""
		else
			method = "3"
		end
	end
	"#{method}"
end

#- Напутствие настройщику ----------------------------------------------------------------------------------------
def settings_message
"# Конфигурационный файл подготовки Rails-проекта к интернационализации
# Строки файла устроены следующим образом:
# mailers/preorder_mailer.rb:                                                              # Имя файла с исходным кодом
#  1:                                                                                      # порядковый номер фразы в исходном коде
#    номер_строки: 8                                                                       # Номер строки с найденной фразой
#    ключ_фразы: \"preorder.заявка_на_уикенд\"                                             # Ключ фразы для yml файла. Можете изменять его
#    оригинал_фразы: \"заявка на уикед\"                                                   # Оригинал найденной фразы в исходном коде
#    новая_версия_фразы: \"заявка на уикенд\"                                              # Новый вариант фразы, можете поменять. Например если фраза написана с ошибкой
#    оригинальная_строка_файла: \"    mail(to: email, subject: 'заявка на уикенд')\"       # Строка файла, содержащая фразу целиком, нужна для понимания контекста
#    действие: \"[]\"                                                                      # Вид действия, которое нужно совершить

# Этап 1. Настройка
#  В нижеследующих строках установите флаг действия по следующему принципу:
#  [] - Не изменять текущую фразу
#  [1] - Заменить как обычную строку Ruby, заключённую в одинарные кавычки, целиком вместе с кавычками.
#        Пример замены: 'ваша фраза' => I18n.t(:ваша_фраза)
#  [2] - То же самое, что и [1], только фраза заключена в двойные кавычки.
#        Пример: \"ваша фраза\" => I18n.t(:ваша_фраза)
#  [3] - Заменить фразу на вычисляемое выражение внутри строки
#        Пример: \"Ваша фраза \#\{index\} Другая фраза\" => \"\#\{I18n.t(\"ваша_фраза\"\} \#\{index\} \#\{I18n.t(\"другая_фраза\")\}\"
#----------------------------------------
# Если хотите, чтобы этот файл не переписывался программой, но вам лень делать копию - Поставьте в первой строке комбинацию из двух символов: #!
#    При дальнейших прогонах программа будет прерывать выполнение, не изменяя этот файл.\n"
end

def do_not_proceed_list
	%w{
controllers/api/v1/partners/orders_controller.rb
controllers/preorders_controller.rb
views/content/pages/
controllers/api/v1/partners/orders_controller.rb
controllers/preorders_controller.rb
views/content/pages/
views/spages/
views/mailers/gettaxi_mailer/promocode_email.html.haml
views/shared/modals/_get_taxi_promo.html.haml
views/shared/banners/_what_is_wt.html.haml
views/events/
controllers/events_controller.rb
views/landing/index.html.haml
views/cities/hotels.html.haml
views/cities/_place.html.haml
views/cities/_event.html.haml
views/users/wishlists/show.html.haml
views/users/wishlists/index.html.haml
views/preorders/
	}
end

#-----------------------------------------------------------------------
if File.exists?("settings.yml")
	File.open("settings.yml", "rb") do |settings_file|
		if settings_file.read(2) == "#!"
			puts "Внимание - файл settings.yml был вами заблокирован от изменения. Если хотите выполнить программу - удалите или переименуйте этот файл".red
			abort
		end
	end
end


#============================================================= туловище
Dir.glob("**/*").each do |entryname|
	if File.directory? entryname
		next
	elsif entryname =~ /localizer.+?\.rb$/ || entryname =~ /\.yml$/ || entryname == "common.rb"
		next
	elsif entryname.split('/')[0..1].include? "admin"
		next
	else
		not_proceed = false
		do_not_proceed_list.each do |filemask|
			if entryname =~ Regexp.new("^#{filemask}")
				not_proceed = true
				break
			end
		end
		next if not_proceed
	end
	if entryname =~ /\.rb$/i
		localize entryname, [0]
	elsif entryname =~ /\.haml$/i
		localize entryname, [0]
	end
end
File.open("settings.yml", "w") do |settings_file|
	settings_file.write settings_message
	settings_file.write $settings.to_yaml(line_width: 500)
end

phrases_count = 0
$settings.each do |key, value|
	phrases_count += value.keys.size
end
puts "Всего найдено фраз для локализации: ".white+"#{phrases_count}".yellow
