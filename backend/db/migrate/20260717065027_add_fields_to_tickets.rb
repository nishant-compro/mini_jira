class AddFieldsToTickets < ActiveRecord::Migration[7.2]
  def change
    add_reference :tickets, :assignee, foreign_key: { to_table: :users }
    add_reference :tickets, :author, foreign_key: { to_table: :users }
  end
end
