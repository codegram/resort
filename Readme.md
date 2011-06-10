#resort

Resort provides sorting capabilities to your Rails 3 models.

##Install

    $ gem install resort

Or in your Gemfile:

```ruby
gem 'resort'
```

##Rationale

Most other sorting plugins work with an absolute `position` attribute that sets
the _weight_ of a given element within a tree. This field has no semantic sense,
since "84" by itself gives you absolutely no information about an element's
position or its relations with other elements of the tree.

Resort is implemented like a [linked list](http://en.wikipedia.org/wiki/Linked_list),
rather than relying on absolute position values. This way, every model
references a `next` element, which seems a bit more sensible :)

##Usage

First, run the migration for the model you want to Resort:

    $ rails generate resort:migration product
    $ rake db:migrate

Then in your Product model:

```ruby
class Product < ActiveRecord::Base
  resort!
end
```

**NOTE**: By default, Resort will treat _all products_ as a single big tree.
If you wanted to limit the tree scope, i.e. treating every ProductLine as a
separate tree of sortable products, you must override the `siblings` method:

```ruby
class Product < ActiveRecord::Base
  resort!

  def siblings
    # Tree contains only products from my own product line
    self.product_line.products
  end
end
```

### Concurrency

Multiple users modifying the same list at the same time could be a problem, 
so it's always a good practice to wrap the changes in a transaction:
    
```ruby
Product.transaction do
  my_product.append_to(another_product)
end
```
        
###API

Every time a product is created, it will be appended after the last element.

Moreover, now a `product` responds to the following methods:

* `first?` &mdash; Returns true if the element is the first of the tree.
* `append_to(other_element)` &mdash; Appends the element _after_ another element.

And the class Product has a new scope named `ordered` that returns the
products in order.

### Examples

Given our 'Product' example defined before, we can do things like:

Getting products in order:
```ruby
Product.first_in_order # returns the first ordered product.
Product.last_in_order # returns the last ordered product.
Product.ordered # returns all products ordered as an Array, not a Relation!
```

Find elements with scopes or conditions ordered:

```ruby
Product.where('price > 10').ordered # => Ordered array of products with price > 10
Product.with_custom_scope.ordered # => Ordered array of products with your custom conditions
```

Modify the list of products:

```ruby
product = Product.create(:name => 'Bread')
product.first? # => true

another_product = Product.create(:name => 'Milk')
yet_another_product = Product.create(:name => 'Salami')

yet_another_product.append_to(product) # puts the products right after the first one

Product.ordered.map(&:name) # => ['Bread', 'Salami', 'Milk']
```

Check neighbours:

```ruby
product = Product.create(:name => 'Bread')
second_product = Product.create(:name => 'Milk')
third_product = Product.create(:name => 'Salami')

second_product.previous.name # => 'Bread'
second_product.next.name # => 'Salami'

third_product.next # => nil
```

Maybe you need different orders depending on the product vendor:

```ruby
class Product < ActiveRecord::Base
  resort!

  belongs_to :vendor

  def siblings
    self.vendor.products
  end
end

bread = Product.create(:name => 'Bread', :vendor => Vendor.where(:name => 'Bread factory'))
bread.first? # => true

milk = Product.create(:name => 'Milk', :vendor => Vendor.where(:name => 'Cow world'))
milk.first? # => true

# milk and product aren't neighbours
```

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
