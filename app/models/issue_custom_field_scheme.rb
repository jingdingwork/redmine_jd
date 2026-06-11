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

class IssueCustomFieldScheme < ApplicationRecord
  include Redmine::SafeAttributes

  has_and_belongs_to_many :issue_custom_fields,
                          lambda {order(:position)},
                          :class_name => 'IssueCustomField',
                          :join_table => "#{table_name_prefix}issue_custom_field_schemes_custom_fields#{table_name_suffix}",
                          :foreign_key => 'issue_custom_field_scheme_id',
                          :association_foreign_key => 'custom_field_id'
  has_many :projects

  acts_as_positioned

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => true
  validates_length_of :name, :maximum => 255

  scope :sorted, lambda {order(:position)}

  safe_attributes(
    'name',
    'description',
    'position',
    'issue_custom_field_ids')

  def <=>(scheme)
    return nil unless scheme.is_a?(IssueCustomFieldScheme)

    position <=> scheme.position
  end

  def to_s
    name
  end
end
