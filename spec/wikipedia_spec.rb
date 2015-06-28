#ruby

require_relative "../wikipedia.rb"

describe WikipediaDocs do
  describe "#api_get" do
    it "should return valid results for querying" do
      jawp = WikipediaDocs.new
      json = jawp.api_get( action: :query, titles: "Main_Page", format: :json )
      expect { JSON.load( json ) }.not_to raise_error
      obj = JSON.load( json )
      expect { JSON.load( json ) }.not_to raise_error
      expect( obj ).to have_key( "query" )
      expect( obj["query"] ).to have_key( "pages" )
      expect( obj["query"]["pages"].values ).not_to be_nil
      expect( obj["query"]["pages"].values.first["title"] ).to eq "Main Page"
    end
  end
  describe "#day_info" do
    it "should return valid results from September 1st" do
      jawp = WikipediaDocs.new
      data = jawp.day_info( Date.new( 2015, 9, 1 ) )
      expect( data ).to have_key :event
      expect( data ).to have_key :birth
      expect( data ).to have_key :death
      expect( data[:event] ).to have_key 1923
      expect( data[:event][1923].first ).to include( "関東大震災" )
    end
  end
  describe "#linkshere" do
    it "should return valid results from September 1st" do
      jawp = WikipediaDocs.new
      data = jawp.linkshere( "9月1日" )
      expect( data.size ).to be 500
    end
  end
  describe "#revisions" do
    it "should return valid results from September 1st" do
      jawp = WikipediaDocs.new
      data = jawp.linkshere( "9月1日" )
      expect( data.size ).to be >= 495
    end
  end
end
