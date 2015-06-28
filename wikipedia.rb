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

  def redirect?( title )
    json = api_get( { action: :query,
                      titles: title,
                      redirects: true,
                      format: :json,
                    } )
    obj = JSON.load( json )
    title2 = obj["query"]["pages"].values.first["title"]
    if title == title2
      false
    else
      title2
    end
  end

  def linkshere( title )
    redirect = redirect? title
    json = api_get( { action: "query",
                      titles: redirect || title,
                      prop: "linkshere",
                      lhnamespace: 0,
                      lhlimit: :max,
                      format: :json,
                    } )
    obj = JSON.load( json )
    result = obj["query"]["pages"].values.first["linkshere"]
    result
  end

  def revisions( title )
    redirect = redirect? title
    params = {
      action: "query",
      titles: redirect || title,
      prop: "revisions",
      rvlimit: :max,
      format: :json,
    }
    json = api_get( params )
    obj = JSON.load( json )
    result = obj["query"]["pages"].values.first["revisions"]
    while obj[ "query-continue" ]
      params = params.update( rvcontinue: obj["query-continue"]["revisions"]["rvcontinue"] )
      json = api_get( params )
      obj = JSON.load( json )
      result += obj["query"]["pages"].values.first["revisions"]
    end
    result
  end

  def get_content( title )
    json = api_get( action: :query, titles: title, prop: :revisions, rvprop: :content, format: :json )
    obj = JSON.load( json )
    wikitext = obj["query"]["pages"].values.first["revisions"].first["*"]
  end

  def day_info( date = Date.today )
    title = "#{ date.month }月#{ date.day }日"
    wikitext = get_content( title )
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
      when /^\*\s*\[\[(\d+)年\]\](（.*?(?:\d+|元)年.*?）)?\s*[:\-]?\s*(.*)$/
        next if section.nil?
        year = $1.to_i
        jp_year = $2
        text = $3
        result[ section ] ||= {}
        result[ section ][ year ] ||= []
        result[ section ][ year ] << text
      end
    end
    result
  end
  
  LINK_REGEXP = /\[\[(.+?)(\|.+?)?\]\]/
  def list_info
    wikitext = get_content "一覧の一覧"
    lists = []
    wikitext.split( /\r?\n/ ).each do |line|
      case line
      when /\A\*\s*#{ LINK_REGEXP }/
        article = $1
        lists << article
      end
    end
    lists
  end

  def wikitext2text( wikitext )
    text = wikitext.gsub( /<!--.*?-->/, "" ).gsub( LINK_REGEXP ) do |m|
      pagename = $1
      pagename_s = $2
      if pagename_s
        if pagename_s.size > 1
          pagename_s[1..-1]
        else
          pagename.sub( / \(.+\)\Z/, "" )
        end
      else
        pagename
      end
    end
    text
  end
end

if $0 == __FILE__
  jawp = WikipediaDocs.new
  data = jawp.list_info
  pp data
  data = jawp.day_info
  #pp jawp.linkshere( "9月1日" )
  #pp jawp.revisions( "9月1日" )
  data[ :event ].each do |k,v|
    v.each do |s|
      text = jawp.wikitext2text( s )
      puts text
      result = []
      s.scan( WikipediaDocs::LINK_REGEXP ).each do |e|
        article = e.first
        backlinks = jawp.linkshere( article )
        revisions = jawp.revisions( article )
        result << [ article, backlinks.size, revisions.size ]
      end
      p result
    end
  end
end
