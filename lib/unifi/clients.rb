require 'ostruct'
module Unifi::Clients
  module_function
  def list(client)
    data = client.get("/api/s/:domain/stat/sta")

    handle_errors(data) unless data.is_a?(Hash)
    ClientList.new(data["data"])
  end

  def handle_errors(data)
  end

  class ClientList
    def initialize(list)
      @list = list.map {|h| OpenStruct.new(h)}
    end

    def all
      @list
    end

    def first
      @list.first
    end
  end
end
