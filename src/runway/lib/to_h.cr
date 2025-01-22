module ToH

  # This method is used to convert the Payload object to a Hash object
  # It preserves the type of the instance variables as well
  def to_h
    {% begin %}
      {
        {% for ivar in @type.instance_vars %}
          "{{ivar.name.id}}": begin
            value = @{{ivar.id}}
            if value.responds_to?(:to_h)
              value.to_h
            else
              value
            end
          end,
        {% end %}
      }
    {% end %}
  end
end
