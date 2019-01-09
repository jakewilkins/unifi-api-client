module Unifi::Camera
  module_function

  def list(client)
    validate_client!(client)
    data = client.get("/api/2.0/bootstrap")

    handle_errors(data) unless data.is_a?(Hash)

    (data['data']&.first&.fetch("cameras") || []).map {|c| OpenStruct.new(c)}
  end

  def set_motion_recording(client, enabled:, camera:)
    body = {
      "_id": camera._id,
      uuid: camera.uuid,
      okToOverrideConflict: true,
      enableSuggestedVideoSettings: true,
      name: camera.name,
      recordingSettings: {
        channel: "0",
        motionRecordEnabled: enabled
      }
    }
    response = client.put(
      "api/2.0/camera/#{camera._id}",
      body: JSON.generate(body)
    )

    OpenStruct.new(response["data"].first)
  end

  def handle_errors(data)
  end

  def validate_client!(client)
    raise "needs a video client" unless client.type == :video
  end

end
