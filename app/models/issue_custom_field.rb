# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class IssueCustomField < CustomField
  has_and_belongs_to_many :projects, :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}", :foreign_key => "custom_field_id", :autosave => true
  has_and_belongs_to_many :trackers, :join_table => "#{table_name_prefix}custom_fields_trackers#{table_name_suffix}", :foreign_key => "custom_field_id", :autosave => true

  safe_attributes 'project_ids',
                  'tracker_ids'

  def type_name
    :label_issue_plural
  end

  def visible_by?(project, user=User.current)
    super || roles.intersect?(user.roles_for_project(project))
  end

  def visibility_by_project_condition(project_key=nil, user=User.current, id_column=nil)
    sql = super
    project_key ||= "#{Issue.table_name}.project_id"
    id_column ||= id
    tracker_condition = "#{Issue.table_name}.tracker_id IN (SELECT tracker_id FROM #{table_name_prefix}custom_fields_trackers#{table_name_suffix} WHERE custom_field_id = #{id_column})"
    project_condition =
      "#{project_key} IN (" \
        "SELECT p.id FROM #{Project.table_name} p" \
        " INNER JOIN #{table_name_prefix}custom_field_schemes_custom_fields#{table_name_suffix} scf" \
        " ON p.custom_field_scheme_id = scf.custom_field_scheme_id" \
        " WHERE scf.custom_field_id = #{id_column})"

    "((#{sql}) AND (#{tracker_condition}) AND (#{project_condition}) AND (#{Issue.visible_condition(user)}))"
  end

  def validate_custom_field
    super
    errors.add(:base, l(:label_role_plural) + ' ' + l('activerecord.errors.messages.blank')) unless visible? || roles.present?
  end
end
