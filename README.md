# Data Structures - An exercise exploring basic data structure types in Ruby

By [Matthew Yang](http://www.matthewgyang.com).

## Description
This Rails app code was forked from [Ivan's Terrible Blog, Insecure Branch](https://github.com/brookr/ivan_the_terribles_blog/tree/insecure) as a class assignment.  Our goal was to fix the vulnerabilities listed below:

XSS:
```
http://localhost:3000/posts?utf8=%E2%9C%93&search=archive&status=foo=%22bar%22%3E%3Cscript%3Ealert%28%22p0wned!!!%22%29%3C/script%3E%3Cp%20data-foo
```

SQL Injection:
```
foo%' OR true) --
```

## Fix

**XSS (Cross-Site Scripting)**

Modified *app/views/posts/_search_form.html.erb*
* Before
```erb
<%= content_tag :div, "data-#{params[:status]}" => @posts.size do %>
  Number of <%= params[:status] %> results shown: <%= @posts.size if @posts %>
<% end -%>
```

* After
```erb
<%= content_tag :div, "data-#{sanitize(params[:status])}" => true do %>
  Now showing <%= sanitize(params[:status]) %> results below:
<% end -%>
```

This method uses the Rails helper `sanitize` to strip out HTML tags before being displaying content, which in this case prevents `<script>` tags from executing a JavaScript alert box.

**SQL Injection**

Modified *app/models/post.rb*
* Before
```ruby
def self.search(search)
  if search
    search.strip
    includes(comments: :replies).where("title like '%#{search}%'")
  else
    includes(comments: :replies).order("updated_at DESC")
  end
end
```

* After
```ruby
def self.search(search)
  if search
    search.strip
    includes(comments: :replies).where("title like ?", "%#{search}%")
  else
    includes(comments: :replies).order("updated_at DESC")
  end
end
```

This method moves the interpolation of `search` outside of the `.where()` field.  Rails automatically sanitizes this string when it is placed back in (see [Section 7.2.4](http://guides.rubyonrails.org/security.html)).

**Credit**
______
[Rails Guides - Security](http://guides.rubyonrails.org/security.html)
