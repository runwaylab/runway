# https://github.com/crystal-lang/shards/blob/9fb4e5ab12e25a1c9c05b375ede27ad6d6eda537/src/versions.cr

module Runway
  module Versions
    # :nodoc:
    struct Segment
      NON_ALPHANUMERIC                           = /[^a-zA-Z0-9]/
      NATURAL_SORT_EXTRACT_NEXT_CHARS_AND_DIGITS = /^(\D*)(\d*)(.*)$/

      protected getter! segment : String

      def initialize(@str : String)
        if index = @str.index('+')
          @str = @str[0...index]
        end
      end

      def next
        @segment, _, @str = @str.partition(NON_ALPHANUMERIC)
        segment
      end

      def empty?
        segment.empty?
      end

      def to_i?
        segment.to_i?(whitespace: false)
      end

      def <=>(b : self)
        natural_sort(segment, b.segment)
      end

      # Original natural sorting algorithm from:
      # https://github.com/sourcefrog/natsort/blob/master/natcmp.rb
      # Copyright (C) 2003 by Alan Davies <cs96and_AT_yahoo_DOT_co_DOT_uk>.
      private def natural_sort(a, b)
        if (a_num = a.to_i?(whitespace: false)) && (b_num = b.to_i?(whitespace: false))
          return a_num <=> b_num
        end

        loop do
          return 0 if a.empty? && b.empty?

          a =~ NATURAL_SORT_EXTRACT_NEXT_CHARS_AND_DIGITS
          a_chars, a_digits, a = $1, $2, $3

          b =~ NATURAL_SORT_EXTRACT_NEXT_CHARS_AND_DIGITS
          b_chars, b_digits, b = $1, $2, $3

          ret = a_chars <=> b_chars
          return ret unless ret == 0

          a_num = a_digits.to_i?(whitespace: false)
          b_num = b_digits.to_i?(whitespace: false)

          if a_num && b_num
            ret = a_num.to_i <=> b_num.to_i
            return ret unless ret == 0
          else
            ret = a_digits <=> b_digits
            return ret unless ret == 0
          end
        end
      end

      def only_zeroes?(&)
        return if empty?
        yield unless to_i? == 0

        loop do
          self.next

          return if empty?
          yield unless to_i? == 0
        end
      end

      def prerelease?
        segment.each_char.any?(&.ascii_letter?)
      end

      def inspect(io)
        @segment.inspect(io)
      end
    end

    def self.sort(versions)
      versions.sort { |a, b| compare(a, b) }
    end

    # A helper function to determine if a version is upgradable based on the current version, the latest version, and the requirement.
    # @param current [String] the current version - Ex: "1.0.0"
    # @param latest [String] the latest version - Ex: "1.1.0"
    # @param requirement [String] the requirement - Ex: ">= 1.0.0"
    # @return [Bool, nil] true if the current version is upgradable, false if it is not, and nil if it is up to date
    # Examples:
    # Runway::Versions.upgradable?("1.0.0", "1.1.0", ">= 1.0.0") # => true
    # Runway::Versions.upgradable?("1.9.0", "2.0.0", "~> 1.1.0") # => false
    # Runway::Versions.upgradable?("1.1.0", "1.1.0", ">= 1.0.0") # => nil
    def self.upgradable?(current : String, latest : String, requirement : String) : Bool?
      up_to_date = Runway::Versions.compare(current, latest) == 0

      # if the current version is up to date, exit early as we are all set and no action is needed
      return nil if up_to_date

      # if it is not up to date, see if there is a valid version to use
      matches_requirement = Runway::Versions.matches?(Runway::Version.new(latest), Runway::VersionReq.new(requirement))

      # if the current version is not up to date and matches the requirement, it is upgradable
      return true if !up_to_date && matches_requirement

      # if the current version is not up to date and does not match the requirement, it is not upgradable
      return false if !up_to_date && !matches_requirement
    end

    def self.compare(a : Version, b : Version)
      compare(a.value, b.value)
    end

    def self.compare(a : String, b : String)
      if a == b
        return 0
      end

      a_segment = Segment.new(a)
      b_segment = Segment.new(b)

      loop do
        # extract next segment from version number ("1.0.2" => "1" then "0" then "2"):
        a_segment.next
        b_segment.next

        # accept unbalanced version numbers ("1.0" == "1.0.0.0", "1.0" < "1.0.1")
        if a_segment.empty?
          b_segment.only_zeroes? { return b_segment.prerelease? ? -1 : 1 }
          return 0
        end

        # accept unbalanced version numbers ("1.0.0.0" == "1.0", "1.0.1" > "1.0")
        if b_segment.empty?
          a_segment.only_zeroes? { return a_segment.prerelease? ? 1 : -1 }
          return 0
        end

        # try to convert segments to numbers:
        a_num = a_segment.to_i?
        b_num = b_segment.to_i?

        ret =
          if a_num && b_num
            # compare numbers (for natural 1, 2, ..., 10, 11 ordering):
            b_num <=> a_num
          elsif a_num
            # b is preliminary version:
            a_segment.only_zeroes? do
              return b_segment <=> a_segment if a_segment.prerelease?
              return -1
            end
            return -1
          elsif b_num
            # a is preliminary version:
            b_segment.only_zeroes? do
              return b_segment <=> a_segment if b_segment.prerelease?
              return 1
            end
            return 1
          else
            # compare strings:
            b_segment <=> a_segment
          end

        # if different return the result (older or newer), otherwise continue
        # to the next segment:
        return ret unless ret == 0
      end
    end

    def self.prerelease?(str : String)
      str.each_char do |char|
        return true if char.ascii_letter?
        break if char == '+'
      end
      false
    end

    def self.has_metadata?(str : String)
      str.includes? '+'
    end

    protected def self.without_prereleases(versions : Array(Version))
      versions.reject { |v| prerelease?(v.value) }
    end

    def self.resolve(versions : Array(Version), requirement : VersionReq)
      versions.select { |version| matches?(version, requirement) }
    end

    def self.matches?(version : Version, requirement : VersionReq)
      requirement.patterns.all? do |pattern|
        matches_single_pattern?(version, pattern)
      end
    end

    private def self.matches_single_pattern?(version : Version, pattern : String)
      case pattern
      when "*", ""
        true
      when /~>\s*([^\s]+)\d*/
        ver = if idx = $1.rindex('.')
                $1[0...idx]
              else
                $1
              end
        matches_approximate?(version.value, $1, ver)
      when /\s*(~>|>=|<=|!=|>|<|=)\s*([^~<>=!\s]+)\s*/
        matches_operator?(version.value, $1, $2)
      else
        matches_operator?(version.value, "=", pattern)
      end
    end

    private def self.matches_approximate?(version, requirement, ver)
      version.starts_with?(ver) &&
        !version[ver.size]?.try(&.ascii_alphanumeric?) &&
        (compare(version, requirement) <= 0)
    end

    private def self.matches_operator?(version, operator, requirement)
      case operator
      when ">="
        compare(version, requirement) <= 0
      when "<="
        compare(version, requirement) >= 0
      when ">"
        compare(version, requirement) < 0
      when "<"
        compare(version, requirement) > 0
      when "!="
        compare(version, requirement) != 0
      else
        compare(version, requirement) == 0
      end
    end
  end
end

module Runway
  struct VersionReq
    getter patterns : Array(String)

    def initialize(patterns)
      @patterns = patterns.split(',', remove_empty: true).map &.strip
    end

    def prerelease?
      patterns.any? do |pattern|
        Versions.prerelease? pattern
      end
    end

    def to_s(io)
      patterns.join(io, ", ")
    end

    def to_yaml(yaml)
      yaml.scalar "version"
      yaml.scalar to_s
    end
  end

  struct Version
    getter value : String

    def initialize(@value)
    end

    def has_metadata?
      Versions.has_metadata? @value
    end

    def prerelease?
      Versions.prerelease? @value
    end

    def to_s(io)
      io << value
    end

    def to_yaml(yaml)
      yaml.scalar "version"
      yaml.scalar value
    end
  end

  abstract struct Ref
  end

  module Any
    extend self

    def to_s(io)
      io << "*"
    end

    def to_yaml(yaml)
    end
  end

  alias Requirement = VersionReq | Version | Ref | Any
end
