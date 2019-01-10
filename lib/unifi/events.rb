module Unifi::Events
  module_function
  def list(client)
    data = client.get("/api/s/:domain/stat/event")

    handle_errors(data) unless data.is_a?(Hash)

    EventList.new(data["data"])
  end

  def handle_errors(data)
  end

  def disconnect_event?(event)
    event.key == EventList::EVENT_ENUMS.key(:wifi_client_disconnected)
  end

  def connect_event?(event)
    event.key == EventList::EVENT_ENUMS.key(:wifi_client_connected)
  end

  class EventList
    EVENT_ENUMS = {
      "EVT_WU_Connected" => :wifi_client_connected,
      "EVT_WU_Disconnected" => :wifi_client_disconnected
    }
    def initialize(list)
      @list = list.map {|e| OpenStruct.new(e)}
    end

    def all; @list; end

    def client_connection_events
      ckey = EVENT_ENUMS.key(:wifi_client_connected)
      dkey = EVENT_ENUMS.key(:wifi_client_disconnected)
      @list.find_all {|e| [ckey, dkey].include?(e.key)}
    end

    def wifi_client_connected
      key = EVENT_ENUMS.key(:wifi_client_connected)
      @list.find_all {|e| e.key == key}
    end

    def wifi_client_disconnected
      key = EVENT_ENUMS.key(:wifi_client_disconnected)
      @list.find_all {|e| e.key == key}
    end
  end
end
