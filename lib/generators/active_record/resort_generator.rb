require 'rails/generators'
require 'rails/generators/active_record'

module Resort
  # Module containing Resort generators
  module Generators

    # Rails generator to add a migration for Resort
    class MigrationGenerator < ActiveRecord::Generators::Base
      # Implement the required interface for `Rails::Generators::Migration`.
      # Taken from `ActiveRecord` code.
      # @see http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
      def self.next_migration_number(dirname)
        if ActiveRecord::Base.timestamped_migrations
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        else
          "%.3d" % (current_migration_number(dirname) + 1)
        end
      end
      
      desc "Creates a Resort migration."
      source_root File.expand_path("../templates", __FILE__)

      # Copies a migration file adding resort fields to a given model
      def copy_migration_file
        migration_template 'migration.rb', "db/migrate/add_resort_fields_to_#{table_name.pluralize}.rb"
      end
    end
  end
end
