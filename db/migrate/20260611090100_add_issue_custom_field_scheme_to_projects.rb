class AddIssueCustomFieldSchemeToProjects < ActiveRecord::Migration[8.1]
  def change
    add_reference :projects, :issue_custom_field_scheme, :index => true
  end
end
