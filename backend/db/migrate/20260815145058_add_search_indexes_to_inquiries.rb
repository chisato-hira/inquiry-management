class AddSearchIndexesToInquiries < ActiveRecord::Migration[8.1]
  def change
    add_index :inquiries, :name, name: "idx_inquiries_name"
    add_index :inquiries, :email, name: "idx_inquiries_email"
  end
end
