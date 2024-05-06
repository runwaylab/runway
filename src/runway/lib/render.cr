require "crinja"

module Runway
  class Render
    def initialize
      @renderer = Crinja.new
    end

    # render a string with optional bindings
    # @param string [String] the string to render
    # @param bindings [NamedTuple?] optional bindings to use in the rendering
    # @return [String] the rendered string
    # bindings should be a NamedTuple or nil
    # if you reference a key in the bindings that doesn't exist, it will raise an error
    # example usage:
    # bindings = {payload: payload.to_h}
    # result = renderer.render("deploying ref: {{ payload.ref }} {{ payload.sha }} {{ payload.id }}!", bindings)
    def render(string : String, bindings : NamedTuple? = nil) : String
      template = @renderer.from_string(string)
      template.render(bindings)
    end
  end
end
