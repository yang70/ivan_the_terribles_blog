# Fix the terrible blog

by [Matthew Yang](http://matthewgyang.com)

## Description
For this assignment we were to fork this blog:  [Ivan's Terrible Blog](https://github.com/brookr/ivan_the_terribles_blog) and increase it's efficiency.  After loading the database, the blog contains 100 blog posts and each blog post has 100 comments.  Each of those comments then has 1 reply.  This makes a total of 10,000 comments and 10,000 replies.

## Strategy
*To begin I need to say that somehow in my work, before I started benchmarking, I ran the `rake load:blog` command twice, therefore all the numbers I speak about below in development were skewed for dealing with a database twice as big.  However the relative numbers should be about the same.*

The first step I took was to load the blog and run a `rails s` command in order to see how slowly the blog would load.  From the initial request, the first load took 185044.5ms, or *over three minutes* to load all the posts, comments and replies!

After looking at the code and remembering what we went over in class, the first step I attempted was a strategy called [eager loading](http://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations).

The original code loaded all posts in the controller with `@posts = Post.all` and then called `<%= render posts %>` in the index view which rendered a post partial for each post.  There were only 200 posts, so off the bat this doesn't seem too terrible, until you realize that each one of those post partials then called a `<%= render comments %>` partial that had to make 100 more database queries for each comment, *and then* 100 more queries for each reply.  All in all it made 40,000 queries to the database!!

To get around this, I changed the index action in the `PostsController` to the following:

```ruby
@posts = Post.includes([comments: :replies])
```
This eager loading method tells Active Record that we want all the `Posts` and include associated `Comments` and `Replies`.  This reduces drastically the number of database queries.  I then rewrote the `index.html.erb` for `Posts` to remove all render calls and replace with a `posts.each do |post|` or similar for each resource.

The query was then reduced to 12264.2ms, or just over 12 seconds, not too bad.

I then tried to put in caching using so called [Russian Doll Caching](http://edgeguides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), however after putting it in at each resource level, performance actually decreased to close to 13 or 14 seconds.  I decided I must not be incorporating it correctly and removed it, preferring to move on to another strategy.

At this point I decided that the main bottleneck was probably the sheer amount of data that is being rendered on the page and instituted the [will_paginate](https://github.com/mislav/will_paginate) gem which loads only the designated number of resources and makes the rest available by clicking on different page numbers.

This was incredibly simple after adding the gem and the controller was changed to:

```ruby
@posts = Post.includes([comments: :replies]).paginate(:page => params[:page], :per_page => 10).order('created_at DESC')
```
I then added `<%= will_paginate @posts %>` and that was it!  This limits the page to loading only the most recent 10 blog posts and their comments/replies. This took page load down to an acceptable 674.8ms, or just over half a second.

## Deploy
The second part of this assignment was to deploy to [Heroku](https://heroku.com) and run against [loadimpact.com](https://loadimpact.com/), which tests your site by gradually increasing the number of requests and testing load times.

After an ill-fated attempt to upgrade the application to Rails 4, I followed the [Heroku instructions](https://devcenter.heroku.com/articles/getting-started-with-rails3) for getting a Rails 3 application up and running and successfully deployed.

I then input the url into LoadImpact and got the following results

[Loadimpact.com results](https://app.loadimpact.com/load-test/eeeee0e3-0d2a-4fab-ac7f-3b84bdfefce0)


<img src="https://s3.amazonaws.com/mystufftoshare/load_impact.png">

I'm not entirely sure how to interpret these results, but from what I can tell, as the initial requests came in, Heroku responded a bit slowly but that response decresed as even as the load increased.  I can only assume this had to do with the Heroku dyno 'spinning up'.  There was then an interesting spike at 16 or 17 virtual users that then leveled off.  Also interestingly, as the number of virtual users decreased, the load time still increased.

All in all, however, I'm happy with the results as the max page load was just over 3 seconds.  Obviously this could be better.

