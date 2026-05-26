module Chat
  class MentionParser
    HANDLE_REGEX = /@([a-z0-9][a-z0-9._\-]*)/i

    def self.call(body, project:)
      new(body, project).call
    end

    def initialize(body, project)
      @body = body.to_s
      @project = project
    end

    def call
      handles = @body.scan(HANDLE_REGEX).flatten.map(&:downcase).uniq
      return [] if handles.empty?

      project_users.select { |u| handles.include?(u.mention_handle) }
    end

    private

    def project_users
      @project_users ||= @project.users.to_a
    end
  end
end
