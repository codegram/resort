require 'rspec'
require 'resort'

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
end
