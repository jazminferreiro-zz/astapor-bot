require_relative '../app/guarani_client'
module MessageHandler
  @message_handlers = {}
  @callback_query_handlers = {}

  DEFAULT = '_default_handler_'.freeze
  PARAM = 1
  CODE = 0

  # module methods
  def self.message_handlers
    @message_handlers
  end

  def self.callback_query_handlers
    @callback_query_handlers
  end

  # called when the module is included
  def self.included(clazz)
    # adding class methods
    clazz.extend ClazzMethods
  end

  def handle(bot, message)
    # instance methods of any class that include it
    handler = find_handler_for(message) || default_handler(message)
    begin
      handler.call(bot, message)
    rescue AstaporApiError => e
      puts e.msg
      default_handler(message).call(bot, message)
    end
  end

  module ClazzMethods
    # class methods of any class that include it
    def on_message(expected_message, &block)
      MessageHandler.message_handlers[expected_message] = block
    end

    def on_response_to(expected_message, &block)
      MessageHandler.callback_query_handlers[expected_message] = block
    end

    def default(&block)
      MessageHandler.message_handlers[DEFAULT] = block
    end
  end

  def first_word(phrase)
    phrase.split(' ')[CODE]
  end

  def parameter(message)
    message.split(' ')[PARAM]
  end

  private

  def find_handler_for(message)
    case message
    when Telegram::Bot::Types::Message
      MessageHandler.message_handlers[first_word(message.text)]
    when Telegram::Bot::Types::CallbackQuery
      MessageHandler.callback_query_handlers[message.message.text]
    end
  end

  def default_handler(message)
    MessageHandler.message_handlers[DEFAULT] ||
      (raise "Unkown message [#{message.inspect}]. Please define new handler or a default handler")
  end
end
