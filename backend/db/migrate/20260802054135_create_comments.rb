class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :inquiry, null: false, foreign_key: true, index: { name: "idx_comments_inquiry_id" }
      t.references :staff, null: true, foreign_key: true
      t.string :comment_type, null: false, limit: 10, default: "manual"
      t.text :content, null: false

      t.datetime :created_at, null: false
    end
  end
end
