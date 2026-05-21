module Chat
  module Presence
    class Tracker
      KEY_PREFIX = "chat:presence:user:".freeze
      TTL = 60.seconds

      class << self
        def track(user)
          Rails.cache.write(key_for(user), { status: "online", last_seen_at: Time.current.iso8601 }, expires_in: TTL)
        end

        def heartbeat(user)
          track(user)
        end

        def untrack(user)
          Rails.cache.delete(key_for(user))
        end

        def status_for(user)
          data = Rails.cache.read(key_for(user))
          data && data[:status] == "online" ? "online" : "offline"
        end

        def online?(user)
          status_for(user) == "online"
        end

        def online_user_ids_for(project)
          project.users.pluck(:id).select { |id| Rails.cache.read("#{KEY_PREFIX}#{id}").present? }
        end

        private

        def key_for(user)
          "#{KEY_PREFIX}#{user.is_a?(User) ? user.id : user.to_i}"
        end
      end
    end
  end
end
