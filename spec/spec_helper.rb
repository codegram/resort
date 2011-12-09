require 'rspec'

module Rails
  class << self
    # 3.0 defaults this, 3.1 does not
    def application
      "application"
    end
  end
end

require 'resort'
require 'logger'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  create_table :articles do |t|
    t.string     :name
    t.integer    :price

    t.boolean :first
    t.references :next

    t.timestamps
  end

  create_table :ordered_lists do |t|
    t.string     :name
    t.timestamps
  end

  create_table :list_items do |t|
    t.string     :name
    t.boolean :first
    t.references :next
    t.references :ordered_list
    t.timestamps
  end
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)

class Article < ActiveRecord::Base
  resort!
end

class OrderedList < ActiveRecord::Base
  has_many :items, :class_name => 'ListItem'
end

class ListItem < ActiveRecord::Base
  belongs_to :ordered_list
  resort!

  default_scope :order => 'created_at desc'

  def siblings
    self.ordered_list.items
  end
end
