module Chat
  class MarkdownRenderer
    ALLOWED_TAGS = %w[a code pre strong em del ul ol li br p blockquote span].freeze
    ALLOWED_ATTRS = %w[href class data-user-id].freeze

    def self.call(body, project: nil, view_context: nil)
      new(body, project: project, view_context: view_context).call
    end

    def initialize(body, project: nil, view_context: nil)
      @body = body.to_s
      @project = project
      @view_context = view_context
    end

    def call
      html = Commonmarker.to_html(@body, options: commonmark_options).strip
      html = sanitize(html)
      html = replace_mentions(html)
      html.html_safe
    end

    private

    def commonmark_options
      {
        extension: { strikethrough: true, autolink: true, tagfilter: true, table: false, tasklist: false },
        render: { hardbreaks: true, unsafe: false, escape: true }
      }
    end

    def sanitize(html)
      fragment = Loofah.fragment(html)
      fragment.scrub!(loofah_scrubber)
      fragment.to_html
    end

    def loofah_scrubber
      Loofah::Scrubber.new do |node|
        next Loofah::Scrubber::CONTINUE unless node.element?

        unless ALLOWED_TAGS.include?(node.name.downcase)
          node.replace(node.children.to_s)
          next Loofah::Scrubber::STOP
        end

        node.attribute_nodes.each do |attr|
          name = attr.name.to_s.downcase
          attr.remove and next unless ALLOWED_ATTRS.include?(name)

          if name == "href"
            value = attr.value.to_s.strip
            attr.remove unless safe_href?(value)
          end
        end

        Loofah::Scrubber::CONTINUE
      end
    end

    def safe_href?(href)
      return false if href.empty?
      return true if href.start_with?("/", "#", "./", "../")

      href.match?(%r{\A(https?://|mailto:)}i)
    end

    def replace_mentions(html)
      return html if @project.nil?

      users_by_handle = @project.users.to_a.index_by(&:mention_handle)
      return html if users_by_handle.empty?

      html.gsub(Chat::MentionParser::HANDLE_REGEX) do |match|
        handle = Regexp.last_match(1).downcase
        user = users_by_handle[handle]
        next match unless user

        mention_link(user)
      end
    end

    def mention_link(user)
      classes = "mention text-indigo-700 bg-indigo-50 rounded px-1 font-medium"
      %(<a href="#" class="#{classes}" data-user-id="#{user.id}">@#{user.full_name.to_s.strip.presence || user.email}</a>)
    end
  end
end
