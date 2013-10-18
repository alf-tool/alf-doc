require 'spec_helper'
module Alf
  describe Doc do

    it "should have a version number" do
      Doc.const_defined?(:VERSION).should be_true
    end

    it 'has valid .yml files' do
      Doc.all.should be_a(Relation)
    end

    it 'has valid predicates' do
      predicates = Doc.query(:predicates)
      predicates.should be_a(Relation)
      predicates.should_not be_empty
    end

    it 'has valid operators' do
      operators = Doc.query(:operators)
      operators.should be_a(Relation)
      operators.should_not be_empty
    end

    it 'has valid aggregators' do
      aggregators = Doc.query(:aggregators)
      aggregators.should be_a(Relation)
      aggregators.should_not be_empty
    end

  end
end
