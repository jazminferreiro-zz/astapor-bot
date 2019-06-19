require 'telegram/bot'
require_relative '../lib/message_handler'
require_relative 'guarani_client'
require 'telegram/bot'
require_relative '../app/helpers/emoji'

DEFAULT_MESSAGE = "Perdon! No se como ayudarte con eso #{Emoji.code(:speak_no_evil)}" \
                   'prueba preguntando de otra forma!'.freeze
EMPTY_COURSES_MSG = 'No hay materias disponibles'.freeze

EMPTY_INSCRIPTIONS_MSG = 'No hay inscripciones realizadas en este momento'.freeze

INSCRIPTIONS_MSG = 'Inscripciones realizadas:'.freeze

APPROVED_COURSES_MSG = 'Cantidad de materias aprobadas '.freeze

GRADES_AVERAGE_MSG = ', promedio general '.freeze

ERROR_MESSAGE = 'Hubo un error en astapor api'.freeze

class Routes
  include MessageHandler

  on_message '/start' do |bot, message|
    response = GuaraniClient.new.welcome_message
    bot.api.send_message(chat_id: message.chat.id,
                         text: "#{response} #{message.from.first_name} #{Emoji.code(:books)}")
  end

  on_message '/oferta' do |bot, message|
    courses = GuaraniClient.new.courses(message.from.username)
    if courses.empty?
      bot.api.send_message(chat_id: message.chat.id, text: EMPTY_COURSES_MSG)
    else
      key_board = courses.map do |course|
        Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{course.name} cupos disponibles: #{course.available_quota}",
                                                       callback_data: course.code.to_s)
      end

      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: key_board)

      bot.api.send_message(chat_id: message.chat.id, text: 'Oferta academica', reply_markup: markup)
    end
  end

  on_message '/inscripciones' do |bot, message|
    inscriptions = GuaraniClient.new.inscriptions(message.from.username)
    if inscriptions.empty?
      bot.api.send_message(chat_id: message.chat.id, text: EMPTY_INSCRIPTIONS_MSG)
    else
      msg = INSCRIPTIONS_MSG
      inscriptions.each do |course|
        msg += " #{course.name},"
      end
      bot.api.send_message(chat_id: message.chat.id, text: msg[0...msg.length - 1])
    end
  end

  on_message '/estado' do |bot, message|
    course_code = param(message.text)
    response = GuaraniClient.new.state(message.from.username, course_code)
    bot.api.send_message(chat_id: message.chat.id, text: response)
  end

  on_message '/promedio' do |bot, message|
    amount_approved, average = GuaraniClient.new.grades_average(message.from.username)
    if amount_approved.zero?
      bot.api.send_message(chat_id: message.chat.id, text: APPROVED_COURSES_MSG + amount_approved.to_s)
    else
      bot.api.send_message(chat_id: message.chat.id, text: APPROVED_COURSES_MSG + amount_approved.to_s + GRADES_AVERAGE_MSG + average.to_s)
    end
  end

  on_response_to 'Oferta academica' do |bot, message|
    puts "response to oferta academica: #{message.data}"
    student_name = message.from.first_name + ' ' + message.from.last_name

    response = Astapor::Course.handle_response(student_name, message.from.username, message.data)
    bot.api.send_message(chat_id: message.message.chat.id, text: response)
  end

  default do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: DEFAULT_MESSAGE)
  end

  error do |bot, message|
    bot.api.send_message(chat_id: message.chat.id, text: ERROR_MESSAGE)
  end
end
