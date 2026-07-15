# frozen_string_literal: true

class DocsController < AdminController
  def show
    @document = Document.find(params[:id] || 'README')
  end
end
