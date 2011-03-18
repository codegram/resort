#resort

Resort provides sorting capabilities to your Rails 3 models.

##Install

    $ gem install resort

Or in your Gemfile:

    gem 'resort'

##Rationale

Most other sorting plugins work with an absolute `position` attribute that sets
the _weight_ of a given element within a tree. This field has no semantic sense,
since "84" by itself gives you absolutely no information about an element's
position or its relations with other elements of the tree.

Resort is implemented like a [linked list](http://en.wikipedia.org/wiki/Linked_list),
rather than relying on absolute position values. This way, every model
references a `next` element, which seems a bit more sensible :)

##Usage

You must add two fields (`next_id` and `first`) to your model's table:

    class AddResortFieldsToProducts < ActiveRecord::Migration
      def self.up
        add_column :products, :next_id, :integer
        add_column :products, :first,   :boolean
      end

      def self.down
        remove_column :products, :next_id
        remove_column :products, :first
      end
    end

Then in your Product model:

    class Product < ActiveRecord::Base
      resort!
    end

**NOTE**: By default, Resort will treat _all products_ as a single big tree.
If you wanted to limit the tree scope, i.e. treating every ProductLine as a
separate tree of sortable products, you must override the `siblings` method:

    class Product < ActiveRecord::Base
      resort!

      def siblings
        # Tree contains only products from my own product line
        self.product_line.products
      end
    end
        
###API

Every time a product is created, it will be appended after the last element.

Moreover, now a `product` responds to the following methods:

* `first?` &mdash; Returns true if the element is the first of the tree.
* `append_to(other_element)` &mdash; Appends the element _after_ another element.

And the class Product has a new scope named `ordered` that returns the
products in order.

##Under the hood

Run the test suite by typing:

    rake spec

You can also build the documentation with the following command:

    rake docs

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send us a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 Codegram. See LICENSE for details.
