# frozen_string_literal: true

class FastIgnore
  class ShebangRule
    attr_reader :negation
    alias_method :negation?, :negation
    undef :negation

    attr_reader :rule

    attr_reader :squashable_type

    def squash(rules)
      ::FastIgnore::ShebangRule.new(::Regexp.union(rules.map(&:rule)).freeze, negation?)
    end

    def initialize(rule, negation)
      @rule = rule
      @negation = negation

      @squashable_type = negation ? 3 : 2

      freeze
    end

    def file_only?
      true
    end

    def dir_only?
      false
    end

    # :nocov:
    def inspect
      "#<ShebangRule #{'allow ' if @negation}#!:#{@rule.to_s[15..-4]}>"
    end
    # :nocov:

    def match?(_, full_path, filename, content)
      return false if filename.include?('.')

      (content || first_line(full_path))&.match?(@rule)
    end

    def shebang?
      true
    end

    private

    def first_line(path) # rubocop:disable Metrics/MethodLength
      file = ::File.new(path)
      first_line = new_fragment = file.sysread(64)
      if first_line.start_with?('#!')
        until new_fragment.include?("\n")
          new_fragment = file.sysread(64)
          first_line += new_fragment
        end
      else
        file.close
        return
      end
      file.close
      first_line
    rescue ::EOFError, ::SystemCallError
      # :nocov:
      file&.close
      # :nocov:
      first_line
    end
  end
end
