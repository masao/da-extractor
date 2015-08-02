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
  describe "#redirect?" do
    it "should return valid results" do
      jawp = WikipediaDocs.new
      redirect = jawp.redirect? "第一回十字軍"
      expect( redirect ).to eq "第1回十字軍"
      redirect = jawp.redirect? "9月1日"
      expect( redirect ).to be_falsy
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
      expect( data[:event][1203].first ).not_to match /建仁/
    end
    it "should omit a Japanese calendar" do
      jawp = WikipediaDocs.new
      data = jawp.day_info( Date.new( 2015, 6, 29 ) )
      expect( data[:event] ).to have_key 1028
      expect( data[:event][1028].first ).not_to match /長元/
      expect( data[:event][1575].first ).not_to match /天正/
      expect( data[:birth][1227].first ).not_to match /安貞/
    end
  end
  describe "#list_info" do
    it "should return valid results" do
      jawp = WikipediaDocs.new
      data = jawp.list_info
      expect( data ).not_to be_empty
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
      data = jawp.revisions( "9月1日" )
      expect( data.size ).to be >= 495
    end
  end
  describe "#wikitext2text" do
    it "should convert wikitext into a text" do
      jawp = WikipediaDocs.new
      text = jawp.wikitext2text( "[[オーストリア・ハンガリー帝国|オーストリア]]と[[セルビア]]が密約を結び、セルビアはオーストリアの保護国化される。" )
      expect( text ).to eq "オーストリアとセルビアが密約を結び、セルビアはオーストリアの保護国化される。"
      text = jawp.wikitext2text( "<!-- foo -->" )
      expect( text ).to be_empty
    end
  end
  describe "#parse_line" do
    it "should parse wikitext" do
      jawp = WikipediaDocs.new
      data = jawp.parse_line "[[承久の乱]]: 幕府に敗れた[[後鳥羽天皇|後鳥羽上皇]]が隠岐に流される。"
      expect( data[0] ).to eq "承久の乱"
      expect( data[1] ).to eq "後鳥羽天皇"
    end
  end
  describe "#get_content" do
    it "should return wikitext" do
      jawp = WikipediaDocs.new
      content = jawp.get_content( "9月1日" )
      expect( content ).to match /'''9月1日'''/
    end
  end
end
