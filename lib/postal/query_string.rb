module Postal
  class QueryString
    def initialize(string)
      @string = string.strip + ' '
    end

    def [](value)
      to_hash[value.to_s]
    end

    def empty?
      to_hash.empty?
    end

    def to_hash
      @hash ||= @string.scan(/([a-z]+)\:\s*(?:(\d{2,4}\-\d{2}-\d{2}\s\d{2}\:\d{2})|\"(.*?)\"|(.*?))(\s|\z)/).each_with_object({}) do |(key, date, string_with_spaces, value), hash|
        actual_value = if date
                         date
                       elsif string_with_spaces
                         string_with_spaces
                       elsif value == '[blank]'
                         nil
                       else
                         value
                       end

        if hash.keys.include?(key.to_s)
          hash[key.to_s] = [hash[key.to_s]].flatten
          hash[key.to_s] << actual_value
        else
          hash[key.to_s] = actual_value
        end
      end
    end
  end
end
