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

class IssueCustomFieldSchemesController < ApplicationController
  layout 'admin'
  self.main_menu = false

  before_action :require_admin
  before_action :find_scheme, :only => [:edit, :update, :destroy]

  helper :custom_fields

  def index
    @schemes = IssueCustomFieldScheme.sorted.preload(:issue_custom_fields).to_a
  end

  def new
    @scheme = IssueCustomFieldScheme.new
    @scheme.safe_attributes = params[:issue_custom_field_scheme]
    if params[:copy].present? && @copy_from = IssueCustomFieldScheme.find_by_id(params[:copy])
      @scheme.attributes = @copy_from.attributes.except('id', 'name', 'position', 'created_at', 'updated_at')
      @scheme.issue_custom_field_ids = @copy_from.issue_custom_field_ids
    end
    load_issue_custom_fields
  end

  def create
    @scheme = IssueCustomFieldScheme.new
    @scheme.safe_attributes = params[:issue_custom_field_scheme]
    if @scheme.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to issue_custom_field_schemes_path
    else
      load_issue_custom_fields
      render :action => 'new'
    end
  end

  def edit
    load_issue_custom_fields
  end

  def update
    @scheme.safe_attributes = params[:issue_custom_field_scheme]
    if @scheme.save
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_update)
          redirect_to issue_custom_field_schemes_path
        end
        format.js {head :ok}
      end
    else
      respond_to do |format|
        format.html do
          load_issue_custom_fields
          render :action => 'edit'
        end
        format.js {head :unprocessable_content}
      end
    end
  end

  def destroy
    if @scheme.projects.exists?
      flash[:error] = l(:error_can_not_delete_issue_custom_field_scheme)
    else
      @scheme.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to issue_custom_field_schemes_path
  end

  private

  def find_scheme
    @scheme = IssueCustomFieldScheme.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def load_issue_custom_fields
    @issue_custom_fields = IssueCustomField.sorted.to_a
  end
end
