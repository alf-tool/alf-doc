require 'spec_helper'
require 'alf/doc/to_html'
module Alf
  module Doc
    describe ToHtml do

      it 'works on an operator' do
        op = Doc.query{ restrict(operators, name: "project") }.tuple_extract
        lambda{
          ToHtml.new.operator(op)
        }.should_not raise_error
      end

      it 'works on a predicate' do
        op = Doc.query{ restrict(predicates, name: "eq") }.tuple_extract
        lambda{
          ToHtml.new.predicate(op)
        }.should_not raise_error
      end

      it 'works on a aggregator' do
        op = Doc.query{ restrict(aggregators, name: "sum") }.tuple_extract
        lambda{
          ToHtml.new.aggregator(op)
        }.should_not raise_error
      end

    end
  end
end
