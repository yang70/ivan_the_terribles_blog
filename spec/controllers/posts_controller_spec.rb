require 'spec_helper'
# define an rspec helper for takes_less_than
require 'benchmark'
RSpec::Matchers.define :take_less_than do |n|
  chain :seconds do; end
  match do |block|
    @elapsed = Benchmark.realtime do
      block.call
    end
    @elapsed <= n
  end
end

describe PostsController, :performance do

  before :each do

    100.times do
      p = Post.create(
        title: Faker::Company.catch_phrase,
        body: Faker::Lorem.paragraphs.join("\n")
      )
      100.times do
        c = p.comments.build( body: Faker::Lorem.paragraphs.join("\n"))
        r = c.replies.build(  body: Faker::Lorem.paragraphs.join("\n"))
        p.save!
      end
    end
  end

  it "should fetch the home page in less than 6 seconds" do
    expect do
      get :index
    end.to take_less_than(6).seconds
  end
end
