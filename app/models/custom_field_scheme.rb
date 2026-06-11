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

class CustomFieldScheme < ApplicationRecord
  include Redmine::SafeAttributes

  # Custom field types that can be scoped per project through a scheme.
  # Their customized object belongs to a project, so the applicable fields
  # can be resolved from the project's scheme.
  PARTICIPATING_TYPES = %w(
    IssueCustomField
    TimeEntryCustomField
    VersionCustomField
    DocumentCustomField
    ProjectCustomField
  ).freeze

  has_and_belongs_to_many :custom_fields,
                          lambda {order(:position)},
                          :class_name => 'CustomField',
                          :join_table => "#{table_name_prefix}custom_field_schemes_custom_fields#{table_name_suffix}",
                          :foreign_key => 'custom_field_scheme_id',
                          :association_foreign_key => 'custom_field_id'
  has_many :projects, :dependent => :nullify

  acts_as_positioned

  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => true
  validates_length_of :name, :maximum => 255

  scope :sorted, lambda {order(:position)}

  safe_attributes(
    'name',
    'description',
    'position',
    'custom_field_ids',
    'project_ids')

  # Returns the scheme's custom fields of the given subclass (e.g. IssueCustomField)
  def custom_fields_of_type(klass)
    custom_fields.select {|field| field.is_a?(klass)}
  end

  def <=>(scheme)
    return nil unless scheme.is_a?(CustomFieldScheme)

    position <=> scheme.position
  end

  def to_s
    name
  end
end
