class AddLockVersionToInquiries < ActiveRecord::Migration[8.1]
  def change
    add_column :inquiries, :lock_version, :integer, null: false, default: 0
  end
end
