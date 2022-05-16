# frozen_string_literal: true

class FastIgnore
  module Builders
    module ShebangOrGitignore
      def self.build(rule, allow, root)
        if rule.delete_prefix!('#!:')
          ::FastIgnore::Builders::Shebang.build(rule, allow, root)
        else
          ::FastIgnore::Builders::Gitignore.build(rule, allow, root)
        end
      end
    end
  end
end
