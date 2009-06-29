class ActionController::Request
  # patched version to not raise on xml parameter parse errors
  def parse_formatted_request_parameters
    return {} if content_length.zero?

    content_type, boundary = self.class.extract_multipart_boundary(content_type_with_parameters)

    # Don't parse params for unknown requests.
    return {} if content_type.blank?

    mime_type = Mime::Type.lookup(content_type)
    strategy = ActionController::Base.param_parsers[mime_type]

    # Only multipart form parsing expects a stream.
    body = (strategy && strategy != :multipart_form) ? raw_post : self.body

    case strategy
      when Proc
        strategy.call(body)
      when :url_encoded_form
        self.class.clean_up_ajax_request_body! body
        self.class.parse_query_parameters(body)
      when :multipart_form
        self.class.parse_multipart_form_parameters(body, boundary, content_length, env)
      when :xml_simple, :xml_node
        @no_raise = true
        body.blank? ? {} : Hash.from_xml(body).with_indifferent_access
      when :yaml
        YAML.load(body)
      when :json
        if body.blank?
          {}
        else
          data = ActiveSupport::JSON.decode(body)
          data = {:_json => data} unless data.is_a?(Hash)
          data.with_indifferent_access
        end
      else
        {}
    end
  rescue Exception => e # YAML, XML or Ruby code block errors
    if @no_raise
      {}
    else
      raise
      { "body" => body,
        "content_type" => content_type_with_parameters,
        "content_length" => content_length,
        "exception" => "#{e.message} (#{e.class})",
        "backtrace" => e.backtrace }
    end
  end
end