class CreateUserIdentities < ActiveRecord::Migration[5.1]
  def change
    create_table :identities do |t|
      t.references :user, type: :uuid, index: true, foreign_key: { on_delete: :cascade }
      t.string :provider
      t.string :uid
      t.string :registration_platform

      t.timestamps
    end
  end

end