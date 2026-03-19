# frozen_string_literal: true

puts 'Clearing existing data...'
Comment.destroy_all
Post.destroy_all
User.destroy_all

puts 'Creating users...'
users = [
  User.create!(name: 'Alice Johnson', email: 'alice@example.com'),
  User.create!(name: 'Bob Smith', email: 'bob@example.com'),
  User.create!(name: 'Carol White', email: 'carol@example.com')
]

puts 'Creating posts...'
posts = [
  Post.create!(
    title: 'Lorem Ipsum',
    content: 
      'Sed luctus dolor sed nisl maximus congue. **Pellentesque** congue egestas vestibulum. ' \
      'Phasellus viverra semper massa nec elementum. Duis fermentum turpis a ullamcorper accumsan. ' \
      'Etiam venenatis vitae enim vitae cursus. Nam in semper velit. Quisque ac mollis augue, ' \
      'non pharetra velit. Integer facilisis nisl vel nibh pulvinar luctus non sit amet arcu. ' \
      'Fusce hendrerit urna nunc, ac ullamcorper massa suscipit ac. Etiam ornare faucibus urna ' \
      'vehicula congue. Pellentesque ac est sit amet purus viverra placerat. Vestibulum ante ipsum ' \
      'primis in faucibus orci luctus et ultrices posuere cubilia curae;',
    user: users.first
  ),
  Post.create!(
    title: 'Turbo Encabulator',
    content: 
      'The original machine had a base-plate of __prefabulated aluminite__, surmounted by a ' \
      'malleable logarithmic casing in such a way that the two main spurving bearings were in a ' \
      'direct line with the pentametric fan. The latter consisted simply of six __hydrocoptic ' \
      'marzlevanes__, so fitted to the ambifacient lunar waneshaft that side fumbling was ' \
      'effectively prevented. The main winding was of the normal lotus-o-delta type placed in ' \
      'panendermic semi-bovoid slots in the stator, every seventh conductor being connected by a ' \
      'non-reversible tremie pipe to the differential girdlespring on the "up" end of the grammeters.',
    user: users.second
  )
]

# Create comments
puts 'Creating comments...'
posts.each do |post|
  # Create 5 comments for each post
  5.times do |i|
    Comment.create!(
      content: "This is comment #{i + 1} on post '#{post.title}'",
      post:,
      user: users.sample # Randomly assign a user
    )
  end
end

puts 'Seed completed! Created:'
puts "- #{User.count} users"
puts "- #{Post.count} posts"
puts "- #{Comment.count} comments"
