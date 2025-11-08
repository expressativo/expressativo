class Board < ApplicationRecord
  belongs_to :project
  has_many :columns, -> { order(position: :asc) }, dependent: :destroy
  
  validates :title, presence: true
  
  # Crear columnas por defecto al crear el tablero
  after_create :create_default_columns
  
  private
  
  def create_default_columns
    columns.create([
      { title: "Por hacer", position: 0 },
      { title: "En progreso", position: 1 },
      { title: "Completado", position: 2 }
    ])
  end
end
