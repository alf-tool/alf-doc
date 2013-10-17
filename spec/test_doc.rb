require 'spec_helper'
module Alf
  describe Doc do

    it "should have a version number" do
      Doc.const_defined?(:VERSION).should be_true
    end

  end
end