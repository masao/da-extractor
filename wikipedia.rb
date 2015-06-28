#!/usr/bin/env ruby

require "net/http"
require "net/https"
require "uri"
require "date"
require "json"
require "pp"

class WikipediaDocs
  attr_reader :connection
  def initialize
    @connection = nil
  end

  def api_get( params )
    url = "https://ja.wikipedia.org/w/api.php?#{ URI.encode_www_form( params ) }"
    uri = URI.parse( url )
    #p url
    unless @connection
      @connection = Net::HTTP.new( uri.host, uri.port )
      @connection.use_ssl = true if uri.scheme == "https"
    end
    @connection.start unless @connection.started?
    response, = @connection.get( uri.request_uri )
    response.body
  end

  def linkshere( titles )
    json = api_get( { action: "query",
                      titles: titles.join( "|" ),
                      prop: "linkshere",
                      lhnamespace: 0,
                      lhlimits: 100,
                      format: json,
                    } )
    obj = JSON.load( json )
    result = {}
    obj["query"]["pages"].values.first["linkshere"]
  end

  def day_info( date = Date.today )
    title = "#{ date.month }月#{ date.day }日"
    json = api_get( { action: "query",
                      titles: title,
                      prop: "revisions",
                      rvprop: "content",
                      format: "json",
                    } )
    obj = JSON.load( json )
    wikitext = obj["query"]["pages"].values.first["revisions"].first["*"]
    result = {}
    section = nil
    wikitext.split( /\r?\n/ ).each do |line|
      case line
      when /^==\s*([^=\s]+?)\s*==$/
        case $1
        when "できごと"
          section = :event
        when "誕生日"
          section = :birth
        when "忌日"
          section = :death
        else
          section = nil
        end
      when /^\*\s*\[\[(\d+)年\]\]\s*[:\-]?\s*(.*)$/
        next if section.nil?
        year = $1.to_i
        text = $2
        result[ section ] ||= {}
        result[ section ][ year ] ||= []
        result[ section ][ year ] << text
      end
    end
    result
  end
end

if $0 == __FILE__
  jawp = WikipediaDocs.new
  pp jawp.day_info
end
