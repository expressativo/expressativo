class PresenceChannel < ApplicationCable::Channel
  def subscribed
    project = Project.for_user(current_user).find_by(id: params[:project_id])
    return reject unless project

    @project_id = project.id
    stream_from project_stream(@project_id)

    Chat::Presence::Tracker.track(current_user)
    broadcast_status("online")
    transmit_snapshot(project)
  end

  def unsubscribed
    Chat::Presence::Tracker.untrack(current_user)
    broadcast_status("offline") if @project_id
  end

  def heartbeat(_data = {})
    Chat::Presence::Tracker.heartbeat(current_user)
    broadcast_status("online") if @project_id
  end

  private

  def project_stream(project_id)
    "presence:project:#{project_id}"
  end

  def broadcast_status(status)
    ActionCable.server.broadcast(project_stream(@project_id), {
      user_id: current_user.id,
      status: status
    })
  end

  def transmit_snapshot(project)
    online_ids = Chat::Presence::Tracker.online_user_ids_for(project)
    online_ids.each do |id|
      transmit(user_id: id, status: "online")
    end
  end
end
