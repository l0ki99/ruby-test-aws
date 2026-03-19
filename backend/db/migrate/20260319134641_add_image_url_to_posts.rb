class AddImageUrlToPosts < ActiveRecord::Migration[7.0]
  def up
    add_column :posts, :image_url, :string

    execute <<~SQL
      UPDATE posts SET image_url = '/cat.png' WHERE title = 'Lorem Ipsum'
    SQL
    execute <<~SQL
      UPDATE posts SET image_url = '/dog.png' WHERE title = 'Turbo Encabulator'
    SQL
  end

  def down
    remove_column :posts, :image_url
  end
end
