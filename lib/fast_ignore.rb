# frozen_string_literal: true

require 'set'
require 'strscan'

class FastIgnore
  class Error < StandardError; end

  require_relative 'fast_ignore/rule_groups'
  require_relative 'fast_ignore/global_gitignore'
  require_relative 'fast_ignore/gitignore_rule_builder'
  require_relative 'fast_ignore/gitignore_include_rule_builder'
  require_relative 'fast_ignore/path_regexp_builder'
  require_relative 'fast_ignore/gitignore_rule_scanner'
  require_relative 'fast_ignore/rule_group'
  require_relative 'fast_ignore/matchers/unmatchable'
  require_relative 'fast_ignore/matchers/shebang_regexp'
  require_relative 'fast_ignore/gitconfig_parser'
  require_relative 'fast_ignore/path_expander'
  require_relative 'fast_ignore/relative_path_joiner'
  require_relative 'fast_ignore/candidate'
  require_relative 'fast_ignore/relative_candidate'
  require_relative 'fast_ignore/matchers/within_dir'
  require_relative 'fast_ignore/matchers/allow_any_dir'
  require_relative 'fast_ignore/matchers/allow_path_regexp'
  require_relative 'fast_ignore/matchers/ignore_path_regexp'
  require_relative 'fast_ignore/patterns'
  require_relative 'fast_ignore/walkers/base'
  require_relative 'fast_ignore/walkers/file_system'
  require_relative 'fast_ignore/walkers/gitignore_collecting_file_system'
  require_relative 'fast_ignore/gitignore_rule_group'
  require_relative 'fast_ignore/builders/shebang'
  require_relative 'fast_ignore/builders/gitignore'
  require_relative 'fast_ignore/builders/shebang_or_gitignore'

  include ::Enumerable

  def initialize(relative: false, root: nil, gitignore: :auto, follow_symlinks: false, **rule_group_builder_args)
    @root = ::File.expand_path(root.to_s, Dir.pwd)
    @gitignore = gitignore
    @rule_group_builder_args = rule_group_builder_args
    @follow_symlinks = follow_symlinks
    @relative = relative
  end

  def allowed?(path, directory: nil, content: nil, exists: nil, include_directories: false)
    walker.allowed?(
      path,
      root: @root,
      directory: directory,
      content: content,
      exists: exists,
      include_directories: include_directories
    )
  end
  alias_method :===, :allowed?

  def to_proc
    method(:allowed?).to_proc
  end

  def each(&block)
    return enum_for(:each) unless block

    prefix = @relative ? '' : @root

    walker.each(@root, prefix, &block)
  end

  def build
    rule_groups = ::FastIgnore::RuleGroups.new(root: @root, gitignore: @gitignore, **@rule_group_builder_args)

    walker_class = @gitignore ? ::FastIgnore::Walkers::GitignoreCollectingFileSystem : ::FastIgnore::Walkers::FileSystem
    @walker = walker_class.new(rule_groups, follow_symlinks: @follow_symlinks)

    freeze
  end

  private

  def walker
    build unless defined?(@walker)

    @walker
  end
end
