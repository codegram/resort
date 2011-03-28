require 'rspec'
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

  create_table :lists do |t|
    t.string     :name
    t.timestamps
  end

  create_table :list_items do |t|
    t.string     :name
    t.boolean :first
    t.references :next
    t.references :list
    t.timestamps
  end
end

# ActiveRecord::Base.logger = Logger.new(STDOUT)

class Article < ActiveRecord::Base
  resort!
end

class List < ActiveRecord::Base
  has_many :items, :class_name => 'ListItem'
end

class ListItem < ActiveRecord::Base
  belongs_to :list
  resort!

  def siblings
    self.list.items
  end
end
