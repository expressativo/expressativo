class QuickNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quick_note, only: [ :update, :destroy ]

  def index
    @quick_notes = current_user.quick_notes
    @new_note = QuickNote.new(color: "yellow")
  end

  def create
    @quick_note = current_user.quick_notes.build(quick_note_params)

    if @quick_note.save
      @new_note = QuickNote.new(color: @quick_note.color)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to quick_notes_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("new_quick_note_form", partial: "quick_notes/form", locals: { note: @quick_note }) }
        format.html { redirect_to quick_notes_path }
      end
    end
  end

  def update
    if @quick_note.update(quick_note_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to quick_notes_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("quick_note_#{@quick_note.id}", partial: "quick_notes/quick_note", locals: { note: @quick_note }) }
        format.html { redirect_to quick_notes_path }
      end
    end
  end

  def destroy
    @quick_note.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to quick_notes_path }
    end
  end

  private

  def set_quick_note
    @quick_note = current_user.quick_notes.find(params[:id])
  end

  def quick_note_params
    params.require(:quick_note).permit(:content, :color)
  end
end
