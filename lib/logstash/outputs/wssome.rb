# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# An wssome output that does nothing.
class LogStash::Outputs::Wssome < LogStash::Outputs::Base
  config_name "wssome"

  # The address to serve websocket data from
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to serve websocket data from
  config :port, :validate => :number, :default => 3232

  # The port to serve websocket data from
  config :cfield, :validate => :string, :default => "type"

  public
  def register
    require "ftw"
    require "logstash/outputs/websocket/app"
    require "logstash/outputs/websocket/pubsub"
    @pubsub = LogStash::Outputs::WebSocket::Pubsub.new
    @pubsub.logger = @logger
    @server = Thread.new(@pubsub) do |pubsub|
      begin
        Rack::Handler::FTW.run(LogStash::Outputs::WebSocket::App.new(pubsub, @logger),
                               :Host => @host, :Port => @port)
      rescue => e
        @logger.error("websocket server failed", :exception => e)
        sleep 1
        retry
      end
    end
  end # def register

  public
  def receive(event)
    if event.get(@cfield) then 
      @pubsub.publish(event.to_json)
    end
  end # def event
end # class LogStash::Outputs::Wssome
