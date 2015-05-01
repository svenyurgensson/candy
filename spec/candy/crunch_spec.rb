require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'logger'

describe Candy::Crunch do

  class PeanutBrittle
    include Candy::Crunch
  end


  describe "connection" do

    it "takes yours if you give it one" do
      c = Mongo::Client.new(['127.0.0.1:27017'])
      PeanutBrittle.connection = c
      PeanutBrittle.connection.cluster.servers.first.address.to_s.should == '127.0.0.1:27017'
    end

    it "creates the default connection if you don't give it one" do
      PeanutBrittle.connection.cluster.servers.first.address.to_s.should == '127.0.0.1:27017'
    end


    xit "uses the Candy.host setting if you don't override it" do
      Candy.host = 'localhost'
      PeanutBrittle.connection.cluster.servers.first.address.to_s.should == "localhost:27017"
    end

    xit "uses the Candy.port setting if you don't override it" do
      Candy.host = 'localhost'
      Candy.port = 33333
      PeanutBrittle.connection.host_port.should == ["localhost", 33333]
    end

    it "uses the Candy.connection_options setting if you don't override it" do
      l = Logger.new(STDOUT)
      l.level = Logger::FATAL
      Candy.connection_options = {:logger => l}
      PeanutBrittle.connection.logger.should eq(Candy.connection.logger)
    end

    it "clears the database when you set it" do
      PeanutBrittle.db.name.should  eq('candy_test')
      PeanutBrittle.connection = nil
      PeanutBrittle.instance_variable_get(:@db).should be_nil
    end



    after(:each) do
      Candy.host = nil
      Candy.port = nil
      Candy.connection_options = nil
      PeanutBrittle.connection = nil
    end
  end

  describe "database" do
    before(:each) do
      Candy.db = nil
    end

    it "takes yours if you give it one" do
      d = Mongo::Database.new(PeanutBrittle.connection, 'test')
      PeanutBrittle.db = d
      PeanutBrittle.db.name.should == 'test'
    end

    it "takes a name if you give it one" do
      PeanutBrittle.db = 'crunchy'
      PeanutBrittle.db.name.should == 'crunchy'
    end

    it "throws an exception if you give it a database type it can't recognize" do
      -> {
        PeanutBrittle.db = 5
      }.should raise_error(Candy::ConnectionError, "The db attribute needs a Mongo::Database object or a name string.")
    end

    it "uses the Candy.db setting if you don't override it" do
      Candy.db = 'foobar'
      PeanutBrittle.db.name.should == 'foobar'
    end

    it "uses your username if you don't give it a default database" do
      Etc.stubs(:getlogin).returns('nummymuffin')
      PeanutBrittle.db.name.should == 'nummymuffin'
    end

    it "uses 'candy' for a DB name if it can't find a username" do
      Etc.expects(:getlogin).returns(nil)
      PeanutBrittle.db.name.should == 'candy'
    end

    it "clears the collection when you set it" do
      PeanutBrittle.db = 'candy_test'
      PeanutBrittle.collection.name.should eq('PeanutBrittle')
      PeanutBrittle.db = nil
      PeanutBrittle.instance_variable_get(:@collection).should be_nil
    end

    it "takes a username and password if you provide them globally" do
      Mongo::Database.any_instance.expects(:authenticate).with('johnny5','is_alive').returns(true)
      Candy.username = 'johnny5'
      Candy.password = 'is_alive'
      PeanutBrittle.db.collection_names.should_not be_nil
    end

    it "takes a username and password if you provide them at the class level" do
      Mongo::Database.any_instance.expects(:authenticate).with('johnny5','is_alive').returns(true)
      PeanutBrittle.username = 'johnny5'
      PeanutBrittle.password = 'is_alive'
      PeanutBrittle.db = 'candy_test'
      PeanutBrittle.db.collection_names.should_not be_nil
    end

    it "does not authenticate if only a username is given" do
      Mongo::Database.any_instance.expects(:authenticate).never
      Candy.username = 'johnny5'
      PeanutBrittle.db.collection_names.should_not be_nil
    end


    it "does not authenticate if only a password is given" do
      Mongo::Database.any_instance.expects(:authenticate).never
      Candy.password = 'is_alive'
      PeanutBrittle.db.collection_names.should_not be_nil
    end

    after(:each) do
      Candy.username = nil
      Candy.password = nil
    end

    after(:all) do
      Candy.db = 'candy_test'  # Get back to our starting point
    end
  end

  describe "collection" do
    it "takes yours if you give it one" do
      c = Mongo::Collection.new(PeanutBrittle.db, 'blah')
      PeanutBrittle.collection = c
      PeanutBrittle.collection.name.should == 'blah'
    end

    it "takes a name if you give it one" do
      PeanutBrittle.collection = 'bleh'
      PeanutBrittle.collection.name.should == 'bleh'
    end

    it "defaults to the class name" do
      PeanutBrittle.collection.name.should == 'PeanutBrittle'
    end

    it "throws an exception if you give it a type it can't recognize" do
      lambda{PeanutBrittle.collection = 17.3}.should raise_error(Candy::ConnectionError, "The collection attribute needs a Mongo::Collection object or a name string.")
    end

  end

  describe "index" do
    it "can be created with just a property name" do
      PeanutBrittle.index(:blah)
      idx = PeanutBrittle.collection.indexes.to_a[1]['key']
      idx.should == {"blah" => Mongo::Index::ASCENDING}
    end

    it "can be created with a direction" do
      PeanutBrittle.index(:fwah, :desc)
      idx = PeanutBrittle.collection.indexes.to_a[1]['key']
      idx.should == {"fwah" => Mongo::Index::DESCENDING}
    end

    it "throws an exception if you give it a type other than :asc or :desc" do
      lambda{PeanutBrittle.index(:yah, 5)}.should raise_error(Candy::TypeError, "Index direction should be :asc or :desc")
    end

    after(:each) do
      PeanutBrittle.collection.indexes.drop_all
    end
  end

  after(:each) do
    PeanutBrittle.connection = nil
  end

end
