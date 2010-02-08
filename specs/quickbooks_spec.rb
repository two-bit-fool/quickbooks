# To test:
# 1) Download and install QuickBooks Start Simple free edition (http://quickbooks.intuit.com/product/about_quickbooks/trials.jsp)
# 2) Load the example company
# 3) Run the tests:
#       spec specs\quickbooks_spec.rb

require File.dirname(__FILE__) + '/spec_helper'

describe "quickbooks" do
  before do
    Quickbooks::Base.setup(:support_simple_start => true)
  end

  it "should connect to the current active quickbooks file" do
    pending
  end

  it "should create a session" do
    Quickbooks::Base.connection.session
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
    Quickbooks::Base.setup(:support_simple_start => true)
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
    existing = Quickbooks::Customer.first(:full_name => 'Graham Roosevelt')
    existing.destroy if existing
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
end
