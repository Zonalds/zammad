# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class ExternalDataSource
  attr_reader :json, :parsed_items, :options

  def initialize(options:, term:, render_context:, limit: 10)
    @term    = term
    @options = options
    @limit   = limit
    @render_context = render_context
  end

  def process
    @json         = fetch_json
    @parsed_items = get_items_list(@json)

    @parsed_items
      .slice(...@limit)
      .map do |elem|
        {
          value: get_item_value(elem),
          label: get_item_label(elem)
        }
      end
  end

  private

  def fetch_json
    response = UserAgent.get(
      search_url,
      {},
      HttpOptions.new(options).build
    )

    raise Errors::NetworkError.new(self, response.error) if !response.success?

    response.data
  rescue ArgumentError, URI::InvalidURIError
    raise Errors::SearchUrlInvalidError, self
  end

  def search_url
    raise Errors::SearchUrlMissingError, self if options[:search_url].blank?

    NotificationFactory::Renderer.new(
      objects:    @render_context,
      template:   options[:search_url].gsub("\#{search.term}", @term),
      escape:     false,
      url_encode: true,
    ).render(debug_errors: false)
  end

  def get_items_list(input)
    path = options[:search_result_list_key]

    array = if path.present?
              input.dig(*path.split('.'))
            else
              input
            end

    raise TypeError if !array
    raise Errors::ListNotArrayParsingError.new(self, path) if !array.is_a?(Array)

    array
  rescue TypeError
    raise Errors::ListPathParsingError.new(self, path)
  end

  def get_item_value(input)
    get_textual_value(:value, input)
  end

  def get_item_label(input)
    get_textual_value(:label, input)
  end

  def get_textual_value(key, input)
    options_key = "search_result_#{key}_key"

    path = options[options_key]

    value = if path.present?
              input.dig(*path.split('.'))
            else
              input
            end

    raise TypeError if value.nil?

    if [String, Numeric, TrueClass, FalseClass].none? { |elem| value.is_a?(elem) }
      raise Errors::ParsingError.class_for(key, :invalid).new(self, path)
    end

    value
  rescue TypeError
    raise Errors::ParsingError.class_for(key, :path).new(self, path)
  end

end
