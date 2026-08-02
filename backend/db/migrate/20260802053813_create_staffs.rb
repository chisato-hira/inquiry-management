class CreateStaffs < ActiveRecord::Migration[8.1]
  def change
    create_table :staffs do |t|
      t.string :name, null: false, limit: 255
      t.string :email, null: false, limit: 255
      t.string :password_digest, null: false, limit: 255

      t.timestamps
    end
    add_index :staffs, :email, unique: true
  end
end
