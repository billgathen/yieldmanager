require File.join(File.dirname(__FILE__), *%w[spec_helper])

describe PatchDetector do
  describe "needs_patching?" do
    before do
      class Object
        include PatchDetector
      end
    end
    
    describe "when invalid arguments are passed" do
      it "should raise an ArgumentError" do
        ruby_version, minimum_ruby_version_for_patch = "", ""
        
        lambda {needs_patching?(:ruby_version => ruby_version, :minimum_ruby_version_for_patch => minimum_ruby_version_for_patch)}.should raise_error
        lambda {needs_patching?()}.should raise_error
        lambda {needs_patching?(:fasdfasdfa => "asdfasdfda", :foo => "bar")}.should raise_error
      end
    end
    
    describe "when the current ruby version is equal to the minimum ruby version require for patch" do
      it "should be true" do
        ruby_version, minimum_ruby_version_for_patch = "1.8.7", "1.8.7"
        needs_patching?(:ruby_version => ruby_version, :minimum_ruby_version_for_patch => minimum_ruby_version_for_patch).should == true        
      end
    end
    
    describe "when the current ruby version is greater than the minimum_ruby_version_for_patch" do
      it "should return true" do
        minimum_ruby_version_for_patch = "1.8.7"
        
        ruby_version_array = %w(1.8.8 1.8.9 1.8.10)
        ruby_version_array.each do |rv|
          needs_patching?(:ruby_version => rv, :minimum_ruby_version_for_patch => minimum_ruby_version_for_patch).should == true                          
        end
      end
    end
    
    describe "when the current ruby version is smaller than the minimum_ruby_version_for_patch" do
      it "should return true" do
        minimum_ruby_version_for_patch = "1.8.7"
        
        ruby_version_array = %w(1.8.2 1.7.7 0.8.10)
        ruby_version_array.each do |rv|
          needs_patching?(:ruby_version => rv, :minimum_ruby_version_for_patch => minimum_ruby_version_for_patch).should == false
        end
      end
    end
  end
end