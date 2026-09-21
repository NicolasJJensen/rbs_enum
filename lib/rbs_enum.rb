require "pathname"
require_relative "rbs_enum/version"

module RbsEnum
  class UnknownType < StandardError; end

  class << self
    attr_writer :sig_root, :strict

    def sig_root
      return @sig_root if defined?(@sig_root)
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        Rails.root.join("sig")
      end
    end

    def strict
      defined?(@strict) ? @strict : false
    end

    def configure
      yield self
    end

    def clear_cache!
      @cache = {}
    end

    def values(type_name, sig_root: nil, strict: nil)
      key = type_name.to_s.sub(/\A::/, "")
      strict = self.strict if strict.nil?
      root = resolve_root(sig_root)
      cache_key = [root&.to_s, key]
      cache = (@cache ||= {})

      result = cache.fetch(cache_key) { scan_for(root, key) }

      if result.empty? && strict
        raise UnknownType,
          "no literal union found for RBS type alias #{key.inspect} under #{root || "(no sig_root set)"}"
      end

      cache[cache_key] = result
    end

    private

    def resolve_root(sig_root)
      chosen = sig_root || self.sig_root
      Pathname.new(chosen) if chosen
    end

    def scan_for(root, key)
      return [] unless root&.directory?

      Dir.glob(root.join("**", "*.rbs").to_s).each do |path|
        block = extract_type_block(File.read(path), key)
        next unless block

        list = scan_union_literals(block)
        return list unless list.empty?
      end

      []
    end

    def extract_type_block(src, key)
      lines = src.lines
      start_idx = nil
      head = nil
      lines.each_with_index do |line, i|
        if (match = line.match(/^\s*type\s+#{Regexp.escape(key)}\s*=\s*(.*)$/))
          start_idx = i
          head = match[1]
          break
        end
      end
      return nil unless start_idx

      buffer = String.new
      buffer << head << "\n"
      lines[(start_idx + 1)..]&.each do |line|
        break if line.match?(/^\s*(type|class|module|interface|end|def|attr_reader|attr_writer|attr_accessor|include|extend|prepend|alias)\b/)
        buffer << line
      end
      buffer
    end

    def scan_union_literals(text)
      stripped = strip_comments(text)
      matches = stripped.scan(/:'([^']+)'|:"([^"]+)"|:([a-zA-Z_][\w]*)|'([^']+)'|"([^"]+)"/)
      has_strings = matches.any? { |match| match[3] || match[4] }
      matches.filter_map do |sym1, sym2, sym3, str1, str2|
        if has_strings
          str1 || str2 || sym1 || sym2 || sym3
        else
          (sym1 || sym2 || sym3 || str1 || str2)&.to_sym
        end
      end
    end

    def strip_comments(text)
      text.each_line.map do |line|
        quote = nil
        escaped = false
        cutoff = line.length
        line.each_char.with_index do |char, index|
          if escaped
            escaped = false
          elsif char == "\\" && quote
            escaped = true
          elsif quote
            quote = nil if char == quote
          elsif char == "'" || char == '"'
            quote = char
          elsif char == "#"
            cutoff = index
            break
          end
        end
        line[0, cutoff]
      end.join
    end
  end
end

begin
  require "rails/railtie"
rescue LoadError
else
  require_relative "rbs_enum/railtie"
end
