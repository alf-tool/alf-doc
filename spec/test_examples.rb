require 'spec_helper'
module Alf
  describe "The examples" do
    Alf::Doc.examples.each do |ex|
      describe ex.source do

        it 'runs without any problem on the examples database' do
          Alf.examples.query(ex.source).should be_a(Relation)
        end

      end
    end
  end
end
