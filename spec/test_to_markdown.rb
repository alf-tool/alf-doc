require 'spec_helper'
require 'alf/doc/to_markdown'
module Alf
  module Doc
    describe ToMarkdown do

      it 'works on an operator' do
        op = Doc.query{ restrict(operators, name: "project") }.tuple_extract
        lambda{
          ToMarkdown.new.operator(op)
        }.should_not raise_error
      end

      it 'works on a predicate' do
        op = Doc.query{ restrict(predicates, name: "eq") }.tuple_extract
        lambda{
          ToMarkdown.new.predicate(op)
        }.should_not raise_error
      end

      it 'works on a aggregator' do
        op = Doc.query{ restrict(aggregators, name: "sum") }.tuple_extract
        lambda{
          ToMarkdown.new.aggregator(op)
        }.should_not raise_error
      end

    end
  end
end
