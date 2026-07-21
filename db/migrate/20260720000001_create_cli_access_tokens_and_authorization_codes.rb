class CreateCliAccessTokensAndAuthorizationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :cli_access_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :name, null: false
      t.string :scopes, default: "read write", null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :cli_access_tokens, :token_digest, unique: true

    create_table :cli_authorization_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code_digest, null: false
      t.string :redirect_uri, null: false
      t.string :code_challenge
      t.string :code_challenge_method
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :cli_authorization_codes, :code_digest, unique: true
    add_index :cli_authorization_codes, :expires_at
  end
end
