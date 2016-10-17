# frozen_string_literal: true
require 'spec_helper'

module Resort
  describe Sortable do
    subject { Article.new }

    context 'when included' do
      it 'creates previous and next relationships' do
        expect(subject).to respond_to(:previous, :next)
      end

      it 'includes base with InstanceMethods' do
        expect(subject.class.ancestors).to include(Sortable::InstanceMethods)
      end
      it 'extend base with ClassMethods' do
        expect((class << subject.class; self; end).ancestors).to include(Sortable::ClassMethods)
      end
      it 'defines a siblings method' do
        expect(subject).to respond_to(:siblings)
      end
    end

    describe 'ClassMethods' do
      describe 'ordering' do
        before do
          Article.destroy_all

          4.times do |i|
            Article.create(name: i.to_s)
          end

          Article.find_by_name('0').append_to(Article.find_by_name('3'))
          Article.find_by_name('1').append_to(Article.find_by_name('3'))
          Article.find_by_name('2').append_to(Article.find_by_name('3'))

          @article1 = Article.find_by_name('3')
          @article2 = Article.find_by_name('2')
          @article3 = Article.find_by_name('1')
          @article4 = Article.find_by_name('0')
        end

        describe '#first_in_order' do
          it 'returns the first element of the list' do
            expect(Article.first_in_order).to eq @article1
          end
        end

        describe '#last_in_order' do
          it 'returns the last element of the list' do
            expect(Article.last_in_order).to eq @article4
          end
        end

        describe '#ordered' do
          it 'returns all elements ordered' do
            expect(Article.ordered).to eq [@article1, @article2, @article3, @article4]
          end
        end

        after do
          Article.destroy_all
        end
      end
    end

    describe 'siblings' do
      before do
        one_list = OrderedList.create(name: 'My list')
        another_list = OrderedList.create(name: 'My other list')

        4.times do |i|
          one_list.items << ListItem.new(name: "My list item #{i}")
          another_list.items << ListItem.new(name: "My other list item #{i}")
        end
      end

      describe '#first_in_order' do
        it 'returns the first element of the list' do
          expect(OrderedList.find_by_name('My list').items.first_in_order.name).to eq 'My list item 0'
          expect(OrderedList.find_by_name('My other list').items.first_in_order.name).to eq 'My other list item 0'
        end
      end

      describe '#last_in_order' do
        it 'returns the last element of the list' do
          expect(OrderedList.find_by_name('My list').items.last_in_order.name).to eq 'My list item 3'
          expect(OrderedList.find_by_name('My other list').items.last_in_order.name).to eq 'My other list item 3'
        end
      end

      describe '#ordered' do
        it 'returns all elements ordered' do
          expect(OrderedList.find_by_name('My list').items.ordered.map(&:name)).to eq ['My list item 0', 'My list item 1', 'My list item 2', 'My list item 3']
          expect(OrderedList.find_by_name('My other list').items.ordered.map(&:name)).to eq ['My other list item 0', 'My other list item 1', 'My other list item 2', 'My other list item 3']
        end

        it 'raises when ordering without scope' do
          expect do
            ListItem.ordered
          end.to raise_error(NoMethodError)
        end
      end

      after do
        OrderedList.destroy_all
        ListItem.destroy_all
      end
    end

    describe 'after create' do
      context 'when there are no siblings' do
        it 'prepends the element' do
          article = Article.create(name: 'first!')

          expect(article).to be_first
          expect(article.next).to be_nil
          expect(article.previous).to be_nil
        end
      end
      context 'otherwise' do
        it 'appends the element' do
          Article.create(name: '1')
          Article.create(name: 'last!')

          article = Article.find_by_name('last!')
          first = Article.find_by_name('1')

          expect(article).to be_last
          expect(article.next_id).to be_nil
          expect(article.previous.name).to eq '1'

          expect(first.next_id).to eq(article.id)
        end
      end
      after do
        Article.destroy_all
      end

      context 'with custom siblings' do
        context 'when there are no siblings' do
          it 'prepends the element' do
            one_list = OrderedList.create(name: 'My list')
            OrderedList.create(name: 'My other list')
            item = ListItem.create(name: 'My list item', ordered_list: one_list)

            expect(item).to be_first
            expect(item.next).to be_nil
            expect(item.previous).to be_nil
          end
        end
        context 'otherwise' do
          it 'appends the element' do
            one_list = OrderedList.create(name: 'My list')
            OrderedList.create(name: 'My other list')
            ListItem.create(name: '1', ordered_list: one_list)
            ListItem.create(name: 'last!', ordered_list: one_list)

            first = ListItem.find_by_name('1')
            last = ListItem.find_by_name('last!')

            expect(last).to be_last
            expect(last.next_id).to be_nil
            expect(last.previous.name).to eq '1'

            expect(first.next_id).to eq(last.id)
          end

          it 'prepends the last element' do
            one_list = OrderedList.create(name: 'My list')
            ListItem.create(name: 'First', ordered_list: one_list)
            ListItem.create(name: 'Second', ordered_list: one_list)
            third = ListItem.create(name: 'Third', ordered_list: one_list)

            third.prepend
            first = ListItem.where(name: 'First', ordered_list_id: one_list).first
            second = ListItem.where(name: 'Second', ordered_list_id: one_list).first
            third = ListItem.where(name: 'Third', ordered_list_id: one_list).first

            expect(first).to_not be_first
            expect(second).to_not be_first
            expect(third).to be_first
            expect(third.next.name).to eq 'First'
            expect(first.next.name).to eq 'Second'
            expect(second.next).to be_nil
          end
        end
        after do
          OrderedList.destroy_all
          ListItem.destroy_all
        end
      end
    end

    describe 'after destroy' do
      context 'when the element is the first' do
        it 'removes the element' do
          article = Article.create(name: 'first!')
          article2 = Article.create(name: 'second!')
          Article.create(name: 'last!')

          article = Article.find_by_name('first!')
          article.destroy

          article2 = Article.find_by_name('second!')

          expect(article2).to be_first
          expect(article2.previous).to be_nil
        end
      end
      context 'when the element is in the middle' do
        it 'removes the element' do
          article = Article.create(name: 'first!')
          article2 = Article.create(name: 'second!')
          article3 = Article.create(name: 'last!')

          article = Article.find_by_name('first!')

          article2 = Article.find_by_name('second!')
          article2.destroy

          article = Article.find_by_name('first!')
          article3 = Article.find_by_name('last!')

          expect(article).to be_first
          expect(article.next.name).to eq 'last!'
          expect(article3.previous.name).to eq 'first!'
        end
      end
      context 'when the element is last' do
        it 'removes the element' do
          Article.create(name: 'first!')
          article2 = Article.create(name: 'second!')
          article3 = Article.create(name: 'last!')

          article3.destroy

          expect(article2.next).to be_nil
        end
      end
      after do
        Article.destroy_all
      end
    end

    describe 'InstanceMethods' do
      before do
        Article.destroy_all
        Article.create(name: '1')
        Article.create(name: '2')
        Article.create(name: '3')
        Article.create(name: '4')

        @article1 = Article.find_by_name('1')
        @article2 = Article.find_by_name('2')
        @article3 = Article.find_by_name('3')
        @article4 = Article.find_by_name('4')
      end

      describe '#push' do
        it 'appends the element to the list' do
          @article1.push

          article1 = Article.find_by_name('1')
          expect(article1.previous).to eq @article4
          expect(article1.next).to be_nil
        end
        context 'when the article is already last' do
          it 'does nothing' do
            @article4.push

            expect(@article4.previous.name).to eq '3'
            expect(@article4.next).to be_nil
          end
        end
      end

      describe '#prepend' do
        it 'prepends the element' do
          @article3.prepend

          article3 = Article.find_by_name('3')

          expect(article3).to be_first
          expect(article3.previous).to be_nil
          expect(article3.next.name).to eq '1'
        end

        it 'prepends the last element' do
          @article4.prepend

          article4 = Article.find_by_name('4')

          expect(article4).to be_first
          expect(article4.previous).to be_nil
          expect(article4.next.name).to eq '1'
        end

        it 'will raise ActiveRecord::RecordNotSaved if update fails' do
          expect(@article2).to receive(:update_attribute).and_return(false)
          expect { @article2.prepend }.to raise_error(ActiveRecord::RecordNotSaved)
        end

        context 'when the article is already first' do
          it 'does nothing' do
            @article1.prepend

            expect(@article1.previous).to be_nil
            expect(@article1.next.name).to eq '2'
          end
        end
      end

      describe '#append_to' do
        it 'will raise ActiveRecord::RecordNotSaved if update fails' do
          expect(@article2).to receive(:update_attribute).and_return(false)
          expect { @article2.append_to(@article3) }.to raise_error(ActiveRecord::RecordNotSaved)
        end

        context 'appending 1 after 2' do
          it 'appends the element after another element' do
            @article1.append_to(@article2)

            article1 = Article.find_by_name('1')
            expect(article1.next.name).to eq '3'
            expect(article1.previous.name).to eq '2'
            expect(@article3.previous.name).to eq '1'
          end

          it 'sets the other element as first' do
            @article1.append_to(@article2)

            article2 = Article.find_by_name('2')
            expect(article2.next.name).to eq '1'
            expect(article2).to be_first
          end
        end

        context 'appending 1 after 3' do
          it 'appends the element after another element' do
            @article1.append_to(@article3)

            article1 = Article.find_by_name('1')
            expect(article1).to_not be_first
            expect(article1.previous.name).to eq '3'
            expect(article1.next.name).to eq '4'

            expect(@article3.next.name).to eq '1'
            expect(@article4.previous.name).to eq '1'
          end

          it 'resets the first element' do
            @article1.append_to(@article3)

            article2 = Article.find_by_name('2')
            expect(article2).to be_first
            expect(article2.previous).to be_nil
          end
        end

        context 'appending 2 after 3' do
          it 'appends the element after another element' do
            @article2.append_to(@article3)

            article1 = Article.find_by_name('1')
            expect(article1.next.name).to eq '3'

            article2 = Article.find_by_name('2')
            expect(article2.previous.name).to eq '3'
            expect(article2.next.name).to eq '4'

            expect(@article3.previous.name).to eq '1'
            expect(@article3.next.name).to eq '2'

            expect(@article4.previous.name).to eq '2'
          end
        end
        context 'appending 2 after 4' do
          it 'appends the element after another element' do
            @article2.append_to(@article4)

            article1 = Article.find_by_name('1')
            article3 = Article.find_by_name('3')

            expect(article1.next.name).to eq '3'
            expect(article3.previous.name).to eq '1'

            article2 = Article.find_by_name('2')
            expect(article2.previous.name).to eq '4'
            expect(article2).to be_last

            expect(@article4.next.name).to eq '2'
          end
        end
        context 'appending 4 after 2' do
          it 'appends the element after another element' do
            @article4.append_to(@article2)

            article3 = Article.find_by_name('3')
            expect(article3.next).to be_nil
            expect(article3.previous.name).to eq '4'

            article4 = Article.find_by_name('4')
            expect(@article2.next.name).to eq '4'
            expect(article4.previous.name).to eq '2'
            expect(article4.next.name).to eq '3'
          end
        end
        context 'appending 3 after 1' do
          it 'appends the element after another element' do
            @article3.append_to(@article1)

            article1 = Article.find_by_name('1')
            expect(article1.next.name).to eq '3'

            article2 = Article.find_by_name('2')
            expect(article2.previous.name).to eq '3'
            expect(article2.next.name).to eq '4'

            article3 = Article.find_by_name('3')
            expect(article3.previous.name).to eq '1'
            expect(article3.next.name).to eq '2'

            expect(@article4.previous.name).to eq '2'
          end
        end

        context 'when the article is already after the other element' do
          it 'does nothing' do
            @article2.append_to(@article1)

            article1 = Article.find_by_name('1')
            article2 = Article.find_by_name('2')

            expect(article1.next.name).to eq '2'
            expect(article2.previous.name).to eq '1'
          end
        end
      end
    end
  end
end
