# frozen_string_literal: true
require 'spec_helper'
require 'action_controller'
require 'action_view'
ActionView::Template::Handlers::ERB::ENCODING_FLAG = ActionView::ENCODING_FLAG
require 'generator_spec/test_case'

module Resort
  module Generators
    describe MigrationGenerator do
      include GeneratorSpec::TestCase
      destination File.expand_path('../../../tmp', __FILE__)
      tests MigrationGenerator
      arguments %w(article)

      before(:all) do
        prepare_destination
        mkdir File.join(test_case.destination_root, 'config')
        run_generator
      end

      it 'generates Resort migration' do
        expect(destination_root).to have_structure {
          directory 'db' do
            directory 'migrate' do
              migration 'add_resort_fields_to_articles' do
                contains 'class AddResortFieldsToArticles'
                contains ':articles, :next_id'
                contains ':articles, :first'
              end
            end
          end
        }
      end
    end
  end
end
