class CreateContact < ActiveRecord::Migration[7.0]
  def change
    create_table :contacts do |t|
      t.string :phone_number
      t.string :email
      t.integer :linked_id
      t.string :link_precedence, null: false
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :contacts, :phone_number
    add_index :contacts, :email
  end
end
