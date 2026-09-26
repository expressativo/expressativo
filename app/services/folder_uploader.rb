# Recrea una estructura de carpetas subida desde el navegador (como Google Drive).
#
# Recibe una lista de entradas { path: "Carpeta/sub/archivo.pdf", signed_id: "..." }
# donde signed_id es el blob ya subido vía Active Storage Direct Upload.
# Las carpetas vacías llegan como { path: "Carpeta/vacia", directory: true }.
# Crea las carpetas intermedias y un Document de tipo :file (ya publicado,
# visible para todo el proyecto como en Drive) por cada archivo.
class FolderUploader
  MAX_FILES = 500
  IGNORED_NAMES = %w[.DS_Store Thumbs.db desktop.ini].freeze

  class Error < StandardError; end

  attr_reader :root_folders, :documents

  def initialize(project:, user:, parent_folder: nil, entries: [])
    @project = project
    @user = user
    @parent_folder = parent_folder
    @entries = Array(entries)
    @root_folders = []
    @documents = []
    @folder_cache = {}
  end

  def call
    entries = normalized_entries
    raise Error, "No se recibieron archivos." if entries.empty?
    raise Error, "Máximo #{MAX_FILES} archivos por subida." if entries.count { |_, signed_id| signed_id } > MAX_FILES

    ActiveRecord::Base.transaction do
      entries.each do |segments, signed_id|
        if signed_id.nil?
          ensure_folder_path(segments)
        else
          folder = ensure_folder_path(segments[0...-1])
          create_document(folder, segments.last, signed_id)
        end
      end
    end

    self
  end

  private

  def normalized_entries
    @entries.filter_map do |entry|
      entry = entry.to_h.with_indifferent_access
      segments = entry[:path].to_s.split("/").map(&:strip).reject { |s| s.blank? || s == "." || s == ".." }
      next if segments.empty?
      next [ segments, nil ] if ActiveModel::Type::Boolean.new.cast(entry[:directory])
      next if entry[:signed_id].blank? || IGNORED_NAMES.include?(segments.last)

      [ segments, entry[:signed_id] ]
    end
  end

  # Crea (o reutiliza) cada carpeta del path. La carpeta raíz de la subida
  # recibe un nombre único si ya existe una con el mismo nombre en el destino,
  # para no mezclar contenido (igual que Drive).
  def ensure_folder_path(segments)
    parent = @parent_folder

    segments.each_with_index do |name, depth|
      key = segments[0..depth]
      parent = @folder_cache[key] ||= begin
        if depth.zero?
          folder = create_folder(unique_folder_name(name, parent), parent)
          @root_folders << folder
          folder
        else
          find_or_create_folder(name, parent)
        end
      end
    end

    parent
  end

  def create_folder(name, parent)
    @project.folders.create!(name: name, parent_folder: parent, created_by: @user)
  end

  def find_or_create_folder(name, parent)
    @project.folders.find_by(name: name, parent_folder_id: parent&.id) || create_folder(name, parent)
  end

  def create_document(folder, filename, signed_id)
    document = @project.documents.build(
      folder: folder,
      name: unique_document_name(filename, folder),
      document_type: :file,
      status: :published,
      created_by: @user
    )
    document.file.attach(signed_id)
    document.save!
    @documents << document
  end

  def unique_folder_name(name, parent)
    uniquify(name) { |candidate| @project.folders.exists?(name: candidate, parent_folder_id: parent&.id) }
  end

  def unique_document_name(name, folder)
    uniquify(name) { |candidate| @project.documents.exists?(name: candidate, folder_id: folder&.id) }
  end

  # "informe.pdf" -> "informe (1).pdf", "informe (2).pdf", ...
  def uniquify(name)
    name = name.truncate(255, omission: "")
    return name unless yield(name)

    ext = File.extname(name)
    base = File.basename(name, ext)
    (1..).each do |n|
      candidate = "#{base} (#{n})#{ext}"
      return candidate unless yield(candidate)
    end
  end
end
