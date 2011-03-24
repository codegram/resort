require 'spec_helper'

class Article < ActiveRecord::Base
  resort!
end

module Resort
  describe Sortable do

    subject { Article.new }

    context 'when included' do
      it 'creates previous and next relationships' do
        subject.should respond_to(:previous, :next)
      end

      it 'includes base with InstanceMethods' do
        subject.class.ancestors.should include(Sortable::InstanceMethods)
      end
      it 'extend base with ClassMethods' do
        (class << subject.class; self; end).ancestors.should include(Sortable::ClassMethods)
      end
      it 'defines a siblings method' do
        subject.class.instance_methods.should include(:siblings)
      end
    end

    describe 'ClassMethods' do
      describe "#first_in_order" do
        it 'returns the first element of the list' do
          first = double :article
          Article.should_receive(:where).with(:first => true).and_return [first]

          Article.first_in_order
        end
      end
      describe "#ordered" do
        before do
          Article.destroy_all

          4.times do |i|
            Article.create(:name => i.to_s)
          end

          @article1 = Article.find_by_name('0')
          @article2 = Article.find_by_name('1')
          @article3 = Article.find_by_name('2')
          @article4 = Article.find_by_name('3')
        end
        it 'returns the first element of the list' do
          Article.ordered.should == [@article1, @article2, @article3, @article4]
        end
        after do
          Article.destroy_all
        end
      end
    end

    describe "after create" do
      context 'when there are no siblings' do
        it 'prepends the element' do
          article = Article.create(:name => 'first!')

          article.should be_first
          article.next.should be_nil
          article.previous.should be_nil
        end
      end
      context 'otherwise' do
        it 'appends the element' do
          Article.create(:name => "1")
          Article.create(:name => 'last!')

          article = Article.find_by_name('last!')

          article.should be_last
          article.previous.name.should == '1'
        end
      end
      after do
        Article.destroy_all
      end
    end

    describe "after destroy" do
      context 'when the element is the first' do
        it 'removes the element' do
          article = Article.create(:name => 'first!')
          article2 = Article.create(:name => 'second!')
          article3 = Article.create(:name => 'last!')

          article = Article.find_by_name('first!')
          article.destroy

          article2 = Article.find_by_name('second!')

          article2.should be_first
          article2.previous.should be_nil
        end
      end
      context 'when the element is in the middle' do
        it 'removes the element' do
          article = Article.create(:name => 'first!')
          article2 = Article.create(:name => 'second!')
          article3 = Article.create(:name => 'last!')

          article = Article.find_by_name('first!')

          article2 = Article.find_by_name('second!')
          article2.destroy

          article = Article.find_by_name('first!')
          article3 = Article.find_by_name('last!')

          article.should be_first
          article.next.name.should == 'last!'
          article3.previous.name.should == 'first!'
        end
      end
      context 'when the element is last' do
        it 'removes the element' do
          article = Article.create(:name => 'first!')
          article2 = Article.create(:name => 'second!')
          article3 = Article.create(:name => 'last!')

          article3.destroy

          article2.next.should be_nil
        end
      end
      after do
        Article.destroy_all
      end
    end

    describe 'InstanceMethods' do
      before do
        Article.destroy_all
        Article.create(:name => "1")
        Article.create(:name => "2")
        Article.create(:name => "3")
        Article.create(:name => "4")

        @article1 = Article.find_by_name('1')
        @article2 = Article.find_by_name('2')
        @article3 = Article.find_by_name('3')
        @article4 = Article.find_by_name('4')
      end
      
      describe "#push" do
        it "appends the element to the list" do
          @article1.push

          article1 = Article.find_by_name('1')
          article1.previous.should == @article4
          article1.next.should be_nil
        end
        context 'when the article is already last' do
          it 'does nothing' do
            @article4.push

            @article4.previous.name.should == '3'
            @article4.next.should be_nil
          end
        end
      end

      describe "#prepend" do
        it "prepends the element" do
          @article3.prepend

          article3 = Article.find_by_name('3')

          article3.should be_first
          article3.previous.should be_nil
          article3.next.name.should == '1'
        end
        context 'when the article is already first' do
          it 'does nothing' do
            @article1.prepend

            @article1.previous.should be_nil
            @article1.next.name.should == '2'
          end
        end
      end

      describe "#append_to" do
        context 'appending 1 after 2' do
          it "appends the element after another element" do
            @article1.append_to(@article2)

            article2 = Article.find_by_name('2')
            article2.next.name.should == '1'

            article1 = Article.find_by_name('1')
            article1.next.name.should == '3'
            article1.previous.name.should == '2'
            @article3.previous.name.should == '1'

            article2.should be_first
          end
        end
        context 'appending 1 after 3' do
          it "appends the element after another element" do
            @article1.append_to(@article3)

            article2 = Article.find_by_name('2')
            article2.should be_first
            article2.previous.should be_nil

            article1 = Article.find_by_name('1')
            article1.should_not be_first
            article1.previous.name.should == '3'
            article1.next.name.should == '4'

            @article3.next.name.should == '1'

            @article4.previous.name.should == '1'
          end
        end
        context 'appending 2 after 3' do
          it "appends the element after another element" do
            @article2.append_to(@article3)

            article1 = Article.find_by_name('1')
            article1.next.name.should == '3'
            
            article2 = Article.find_by_name('2')
            article2.previous.name.should == '3'
            article2.next.name.should == '4'

            @article3.previous.name.should == '1'
            @article3.next.name.should == '2'

            @article4.previous.name.should == '2'
          end
        end
        context 'appending 2 after 4' do
          it "appends the element after another element" do
            @article2.append_to(@article4)

            article1 = Article.find_by_name('1')
            article3 = Article.find_by_name('3')

            article1.next.name.should == '3'
            article3.previous.name.should == '1'

            article2 = Article.find_by_name('2')
            article2.previous.name.should == '4'
            article2.should be_last

            @article4.next.name.should == '2'
          end
        end
        context 'appending 4 after 2' do
          it "appends the element after another element" do
            @article4.append_to(@article2)

            article3 = Article.find_by_name('3')
            article3.next.should be_nil
            article3.previous.name.should == '4'

            article4 = Article.find_by_name('4')
            @article2.next.name.should == '4'
            article4.previous.name.should == '2'
            article4.next.name.should == '3'
          end
        end
        context 'appending 3 after 1' do
          it "appends the element after another element" do
            @article3.append_to(@article1)

            article1 = Article.find_by_name('1')
            article1.next.name.should == '3'
            
            article2 = Article.find_by_name('2')
            article2.previous.name.should == '3'
            article2.next.name.should == '4'

            article3 = Article.find_by_name('3')
            article3.previous.name.should == '1'
            article3.next.name.should == '2'

            @article4.previous.name.should == '2'
          end
        end

        context 'when the article is already after the other element' do
          it 'does nothing' do
            @article2.append_to(@article1)

            article1 = Article.find_by_name('1')
            article2 = Article.find_by_name('2')

            article1.next.name.should == '2'
            article2.previous.name.should == '1'
          end
        end
      end
    end

  end
end
