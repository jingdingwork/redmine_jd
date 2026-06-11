class CreateIssueCustomFieldSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_custom_field_schemes do |t|
      t.string :name, :null => false
      t.text :description
      t.integer :position
      t.timestamps :null => false
    end

    add_index :issue_custom_field_schemes, :name, :unique => true

    create_table :issue_custom_field_schemes_custom_fields, :id => false do |t|
      t.integer :issue_custom_field_scheme_id, :null => false
      t.integer :custom_field_id, :null => false
    end

    add_index(
      :issue_custom_field_schemes_custom_fields,
      [:issue_custom_field_scheme_id, :custom_field_id],
      :unique => true,
      :name => 'idx_issue_cf_schemes_fields'
    )
    add_index(
      :issue_custom_field_schemes_custom_fields,
      :custom_field_id,
      :name => 'idx_issue_cf_schemes_fields_cf'
    )
  end
end
