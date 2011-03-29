# Migration to add the necessary fields to a resorted model
class AddResortFieldsTo<%= table_name.camelize %> < ActiveRecord::Migration
  # Adds Resort fields, next_id and first, and indexes to a given model
  def self.up
    add_column :<%= table_name %>, :next_id, :integer
    add_column :<%= table_name %>, :first,   :boolean
    add_index :<%= table_name %>, :next_id
    add_index :<%= table_name %>, :first
  end

  # Removes Resort fields
  def self.down
    remove_column :<%= table_name %>, :next_id
    remove_column :<%= table_name %>, :first
  end
end

