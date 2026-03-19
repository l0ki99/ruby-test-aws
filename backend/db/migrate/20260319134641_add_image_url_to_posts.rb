class AddImageUrlToPosts < ActiveRecord::Migration[7.0]
  def change
    add_column :posts, :image_url, :string
  end
end
