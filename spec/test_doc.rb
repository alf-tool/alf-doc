require 'spec_helper'
module Alf
  describe Doc do

    it "should have a version number" do
      Doc.const_defined?(:VERSION).should be_true
    end

    Path.backfind('doc').glob('**/*.yml') do |file|
      describe file.basename do

        subject{ file.load }

        it 'is valid YAML' do
          lambda{
            subject
          }.should_not raise_error
        end
      end
    end

  end
end
