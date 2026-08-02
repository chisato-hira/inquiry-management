class CreateInquiries < ActiveRecord::Migration[8.1]
  def change
    create_table :inquiries do |t|
      t.string :name, null: false, limit: 255
      t.string :email, null: false, limit: 255
      t.string :phone, limit: 20
      t.string :category, null: false, limit: 50
      t.text :content, null: false
      t.string :status, null: false, limit: 20, default: "未対応"
      t.string :priority, limit: 10, default: "未設定"
      t.references :staff, null: true, foreign_key: true, index: { name: "idx_inquiries_staff_id" }

      t.timestamps
    end

    add_index :inquiries, :status, name: "idx_inquiries_status"
    add_index :inquiries, :created_at, name: "idx_inquiries_created_at"
  end
end
