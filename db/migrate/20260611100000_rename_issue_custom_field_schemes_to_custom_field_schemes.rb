class RenameIssueCustomFieldSchemesToCustomFieldSchemes < ActiveRecord::Migration[8.1]
  def up
    rename_table :issue_custom_field_schemes, :custom_field_schemes
    rename_table :issue_custom_field_schemes_custom_fields, :custom_field_schemes_custom_fields
    rename_column :custom_field_schemes_custom_fields, :issue_custom_field_scheme_id, :custom_field_scheme_id
    rename_column :projects, :issue_custom_field_scheme_id, :custom_field_scheme_id

    if index_name_exists?(:projects, 'index_projects_on_issue_custom_field_scheme_id')
      rename_index :projects, 'index_projects_on_issue_custom_field_scheme_id', 'index_projects_on_custom_field_scheme_id'
    end
  end

  def down
    if index_name_exists?(:projects, 'index_projects_on_custom_field_scheme_id')
      rename_index :projects, 'index_projects_on_custom_field_scheme_id', 'index_projects_on_issue_custom_field_scheme_id'
    end

    rename_column :projects, :custom_field_scheme_id, :issue_custom_field_scheme_id
    rename_column :custom_field_schemes_custom_fields, :custom_field_scheme_id, :issue_custom_field_scheme_id
    rename_table :custom_field_schemes_custom_fields, :issue_custom_field_schemes_custom_fields
    rename_table :custom_field_schemes, :issue_custom_field_schemes
  end
end
