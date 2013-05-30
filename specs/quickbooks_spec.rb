# To Test:
# 1) Download and install QuickBooks Start Simple free edition (http://quickbooks.intuit.com/product/about_quickbooks/trials.jsp)
# 2) Open QuickBooks and create a new company, named: test
# 3) Save it to the spec directory as test.qbw (and leave quickbooks open)
# 4) Run the tests: spec specs\*_spec.rb
#
# Note: QuickBooks should't need to be open after approving it the first time

require File.dirname(__FILE__) + '/spec_helper'

if MS_WINDOWS

  ONE_HOUR = 3600

  describe "quickbooks" do
    before do
      Quickbooks::Customer.all.each do |cust|
        cust.destroy if cust
      end
      Quickbooks::Customer.new(
        :name       => 'Doe, John',
        :first_name => 'John',
        :last_name  => 'Doe',
        :phone      => '555-333-9999'
      ).save
    end

    it "should perform an example qbXML query" do
      xml = <<-EOL
<?xml version="1.0" ?>
<?qbxml version="5.0" ?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <CustomerQueryRq requestID="4997">
      <IncludeRetElement>ListID</IncludeRetElement>
    </CustomerQueryRq>
  </QBXMLMsgsRq>
</QBXML>
  EOL
      Quickbooks::Base.connection.send_xml(xml)
    end

    it "should gather all clients" do
      Quickbooks::Customer.all
    end

    it "should grab the first client" do
      j = Quickbooks::Customer.first
      j.last_name.should be_kind_of(String)
      j.last_name.size.should > 0
    end

    it "should instantiate objects into the class they should be" do
      Quickbooks::Customer.first.should be_is_a(Quickbooks::Customer)
    end

    it "should update the first client's phone number" do
      j = Quickbooks::Customer.first
      old_phone = j.phone
      new_phone = '523-998-8821'
      j.phone = new_phone
      j.save
      j.reload
      j.phone.should eql(new_phone)
    end

    it "should respect changes made by other people when updating a record, if they don't update the same attributes" do
      original = Quickbooks::Customer.first
      original.phone = '555-123-4567'
      original.salutation = 'Dr.'
      original.save
      j = Quickbooks::Customer.first
      k = Quickbooks::Customer.first
      j.phone = '222-093-8443'
      k.salutation = 'Jr.'
      j.save
      k.save
      after = Quickbooks::Customer.first
      after.phone.should == '222-093-8443'
      after.salutation.should == 'Jr.'
      j.reload
      k.reload
      k.edit_sequence.should eql(j.edit_sequence)
    end

    it "should not save anything, and leave you with a dirty object, if the record has conflicts" do
      original = Quickbooks::Customer.first
      original.phone = '555-123-4567'
      original.salutation = 'Dr.'
      original.save
      j = Quickbooks::Customer.first
      k = Quickbooks::Customer.first
      # Set the values: j only gets the phone, but k gets phone and new salutation.
      j.phone = '222-093-8443'
      k.phone = '028-981-0092'
      k.salutation = 'Jr.'
      # Should succeed saving...
      j.save.should eql(true)
      # Should return false, but should have saved the salutation
      k.save.should eql(false)
      j.reload
      # j reflects the database and is not dirty
      j.phone.should eql('222-093-8443')
      j.salutation.should eql('Dr.')
      # k's original_attributes should equal j's attributes, but k should be dirtied by its own phone number
      k.phone.should eql('028-981-0092')
      k.salutation.should eql('Jr.')
      k.original_values['salutation'].should eql('Dr.')
      k.original_values['phone'].should eql('222-093-8443')
      k.should be_dirty
    end

    it "should add a client" do
      j = Quickbooks::Customer.new(:name => 'Graham Roosevelt')
      j.save
      j.list_id.should_not be_nil
    end

    it "should find a client by name" do
      Quickbooks::Customer.new(:name => 'Graham Roosevelt').save
      j = Quickbooks::Customer.first(:full_name => 'Graham Roosevelt')
      j.should_not be_nil
      j.full_name.should eql('Graham Roosevelt')
    end

    it "should destroy a client" do
      Quickbooks::Customer.new(:name => 'Graham Roosevelt').save
      j = Quickbooks::Customer.first(:full_name => 'Graham Roosevelt')
      j.should_not be_nil
      j.destroy
       Quickbooks::Customer.first(:full_name => 'Graham Roosevelt').should be_nil
     end

    it "should raise an error for an invalid filter" do
      lambda{
        Quickbooks::Customer.all(:foobar => 7)
      }.should raise_error(ArgumentError)
    end

    it "should not raise an error for a valid filter" do
      lambda{
        Quickbooks::Customer.all(:active_status => 'ActiveOnly')
      }.should_not raise_error
    end

    it "should not raise an error for a time filter" do
      lambda{
        Quickbooks::Customer.all(:created_after => Time.now)
      }.should_not raise_error
    end


    # NOTE: time filtering specs fail when using the QuickBooks example company
    #       because Quickbooks sets its internal clock to a future date (2013).
    describe "time created filters" do

      before do
        @old_customer_name = 'Slightly New Customer'
        @new_customer_name = 'A Very New Customer'
        Quickbooks::Customer.new(:name => @old_customer_name).save
        sleep(2) #QB doesn't do fractions of a second
        @new_customer_time = Time.now
        @new_customer_time += ONE_HOUR if @new_customer_time.dst? # QuickBooks ignores daylight saving
        Quickbooks::Customer.new(:name => @new_customer_name).save
        Quickbooks::Customer.all.size.should > 0
        Quickbooks::Customer.all.map{|c| c.name}.should include(@new_customer_name)
      end

      it "should respect the created_before filter" do
        results = Quickbooks::Customer.all(:created_before => @new_customer_time)
        results.map{|c| c.name}.should include(@old_customer_name)
        results.map{|c| c.name}.should_not include(@new_customer_name)
      end

      it "should respect the created_after filter" do
        results = Quickbooks::Customer.all(:created_after => @new_customer_time)
        results.map{|c| c.name}.should_not include(@old_customer_name)
        results.map{|c| c.name}.should include(@new_customer_name)
      end

    end


    describe "time deleted filters" do

      before do
        old_customer_name = "Customer ##{rand(1000)}"
        new_customer_name = old_customer_name.succ
        old_customer = Quickbooks::Customer.new(:name => old_customer_name)
        new_customer = Quickbooks::Customer.new(:name => new_customer_name)
        old_customer.save
        new_customer.save
        @old_customer_id = old_customer.list_id
        @new_customer_id = new_customer.list_id
        Quickbooks::Customer.first(:list_id => @old_customer_id).destroy
        sleep(2) #QB doesn't do fractions of a second
        @deletion_time = Time.now
        @deletion_time += ONE_HOUR if @deletion_time.dst? # QuickBooks ignores daylight saving
        Quickbooks::Customer.first(:list_id => @new_customer_id).destroy
      end

      it "should respect the deleted_before filter" do
        results = Quickbooks::Customer.deleted(:deleted_before => @deletion_time)
        results.map{|c| c.list_id}.should include(@old_customer_id)
        results.map{|c| c.list_id}.should_not include(@new_customer_id)
      end

      it "should respect the deleted_after filter" do
        results = Quickbooks::Customer.deleted(:deleted_after => @deletion_time)
        #TODO: change the query method to always return an array unless we call "first"
        results = [results].flatten
        results.map{|c| c.list_id}.should_not include(@old_customer_id)
        results.map{|c| c.list_id}.should include(@new_customer_id)
      end

    end


  end

end
