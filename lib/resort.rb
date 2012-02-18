require 'generators/active_record/resort_generator' if defined?(Rails)
require 'active_record' unless defined?(ActiveRecord)

# # Resort
#
# A tool that allows any ActiveRecord model to be sorted.
#
# Unlike most Rails sorting plugins (acts_as_list, etc), Resort is based
# on linked lists rather than absolute position fields.
#
# @example Using Resort in an ActiveRecord model
#     # In the migration
#     create_table :products do |t|
#       t.text       :name
#       t.references :next
#       t.boolean    :first
#     end
#
#     # Model
#     class Product < ActiveRecord::Base
#       resort!
#
#       # A sortable model must implement #siblings method, which should
#       # return and ActiveRecord::Relation with all the models to be
#       # considered as `peers` in the list representing the sorted
#       # products, i.e. its siblings.
#       def siblings
#         self.class.scoped
#       end
#     end
#
#     product = Product.create(:name => 'Bread')
#     product.first? # => true
#
#     another_product = Product.create(:name => 'Milk')
#     yet_another_product = Product.create(:name => 'Salami')
#
#     yet_another_product.append_to(product)
#
#     Product.ordered.map(&:name)
#     # => ['Bread', 'Salami', 'Milk']
module Resort
  # The module encapsulating all the Resort functionality.
  #
  # @todo Refactor into a more OO solution, maybe implementing a LinkedList
  #   object.
  module Sortable
    class << self
      # When included, extends the includer with {ClassMethods}, and includes
      # {InstanceMethods} in it.
      #
      # It also establishes the required relationships. It is necessary that
      # the includer table has the following database columns:
      #
      #     t.references :next
      #     t.boolean :first
      #
      # @param [ActiveRecord::Base] base the includer `ActiveRecord` model.
      def included(base)
        base.extend ClassMethods
        base.send :include, InstanceMethods

        base.has_one :previous, :class_name => base.name, :foreign_key => 'next_id', :inverse_of => :next
        base.belongs_to :next, :class_name => base.name, :inverse_of => :previous

        base.after_create :include_in_list!
        base.after_destroy :delete_from_list
      end
    end

    # Class methods to be used from the model class.
    module ClassMethods
      # Returns the first element of the list.
      #
      # @return [ActiveRecord::Base] the first element of the list.
      def first_in_order
        scoped.where(:first => true).first
      end

      # Returns the last element of the list.
      #
      # @return [ActiveRecord::Base] the last element of the list.
      def last_in_order
        scoped.where(:next_id => nil).first
      end

      
      # Returns eager-loaded Components in order.
      #
      # OPTIMIZE: Use IdentityMap when available
      # @return [Array<ActiveRecord::Base>] the ordered elements
      def ordered
        ordered_elements = []
        elements = {}

        scoped.each do |element|
          if ordered_elements.empty? && element.first?
            ordered_elements << element
          else
            elements[element.id] = element
          end
        end

        raise "Multiple or no first items in the list where found. Consider defining a siblings method" if ordered_elements.length != 1 && elements.length > 0
        
        elements.length.times do
          ordered_elements << elements[ordered_elements.last.next_id]
        end
        ordered_elements.compact
      end
    end

    # Instance methods to use.
    module InstanceMethods

      # Default definition of siblings, i.e. every instance of the model.
      #
      # Can be overriden to specify a different scope for the siblings.
      # For example, if we wanted to limit a products tree inside a ProductLine
      # scope, we would do the following:
      #
      #     class Product < ActiveRecord::Base
      #       belongs_to :product_line
      #
      #       resort!
      #
      #       def siblings
      #         self.product_line.products
      #       end
      #
      # This way, every product line is an independent tree of sortable
      # products.
      #
      # @return [ActiveRecord::Relation] the element's siblings relation.
      def siblings
        self.class.scoped
      end
      # Includes the object in the linked list.
      #
      # If there are no other objects, it prepends the object so that it is
      # in the first position. Otherwise, it appends it to the end of the
      # empty list.
      def include_in_list!
        self.class.transaction do
          self.lock!
          _siblings.count > 0 ? last!\
                              : prepend
        end
      end

      # Puts the object in the first position of the list.
      def prepend
        self.class.transaction do
          self.lock!
          return if first?
          if _siblings.count > 0
            delete_from_list
            old_first = _siblings.first_in_order
            raise(ActiveRecord::RecordNotSaved) unless self.update_attribute(:next_id, old_first.id)
            raise(ActiveRecord::RecordNotSaved) unless old_first.update_attribute(:first, false)
          end
          raise(ActiveRecord::RecordNotSaved) unless self.update_attribute(:first, true)
        end
      end

      # Puts the object in the last position of the list.
      def push
        self.class.transaction do
          self.lock!
          self.append_to(_siblings.last_in_order) unless last?
        end
      end

      # Puts the object right after another object in the list.
      def append_to(another)
        self.class.transaction do
          self.lock!
          return if another.next_id == id
          another.lock!
          delete_from_list
          if self.next_id or (another && another.next_id)
            raise(ActiveRecord::RecordNotSaved) unless self.update_attribute(:next_id, another.next_id)
          end
          if another
            raise(ActiveRecord::RecordNotSaved) unless another.update_attribute(:next_id, self.id)
          end
        end
      end

      private

      def delete_from_list
        if first? && self.next
          self.next.lock!
          raise(ActiveRecord::RecordNotSaved) unless self.next.update_attribute(:first, true)
        elsif self.previous
          self.previous.lock!
          p = self.previous
          self.previous = nil unless frozen?
          raise(ActiveRecord::RecordNotSaved) unless p.update_attribute(:next_id, self.next_id)
        end
        unless frozen?
          self.first = false 
          self.next = nil 
          save!
        end
      end

      def last?
        !self.first && !self.next_id
      end

      def last!
        self.class.transaction do
          self.lock!
          raise(ActiveRecord::RecordNotSaved) unless _siblings.last_in_order.update_attribute(:next_id, self.id)
        end
      end

      def _siblings
        table = self.class.arel_table
        siblings.where(table[:id].not_eq(self.id))
      end
    end
  end
  # Helper class methods to be injected into ActiveRecord::Base class.
  # They will be available to every model.
  module ClassMethods
    # Helper class method to include Resort::Sortable in an ActiveRecord
    # model.
    def resort!
      include Sortable
    end
  end
end

ActiveRecord::Base.extend Resort::ClassMethods
