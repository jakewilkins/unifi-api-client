module Unifi::Camera
  module_function

  def list(client)
    validate_client!(client)
    data = client.get("/api/2.0/bootstrap")

    handle_errors(data) unless data.is_a?(Hash)

    data
  end

  def set_motion_recording(client, enabled:, camera:)
  end

  def handle_errors(data)
  end

  def validate_client!(client)
    raise "needs a video client" unless client.type == :video
  end

end
