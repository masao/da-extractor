#ruby

require_relative "../wikipedia.rb"

describe WikipediaDocs do
  context "#api_get" do
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
end
