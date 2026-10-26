# Datos demo ficticios para las capturas del README
pw = "password123"
mk = ->(email, f, l) { User.find_or_create_by!(email: email) { |u| u.password = pw; u.password_confirmation = pw; u.first_name = f; u.last_name = l } }
ana   = mk.("ana@demo.test", "Ana", "García")
luis  = mk.("luis@demo.test", "Luis", "Pérez")
marta = mk.("marta@demo.test", "Marta", "Ruiz")
dani  = mk.("dani@demo.test", "Daniel", "Soto")
team = [ana, luis, marta, dani]

def project_for(title, desc, owner, members)
  p = Project.find_or_create_by!(title: title) { |pr| pr.description = desc }
  ProjectUser.find_or_create_by!(project: p, user: owner) { |pu| pu.role = "owner" }
  members.each { |m| ProjectUser.find_or_create_by!(project: p, user: m) { |pu| pu.role = "member" } }
  p
end

web = project_for("Rediseño web 2026", "Nueva web corporativa: diseño, contenido y lanzamiento.", ana, [luis, marta, dani])
project_for("App móvil", "Primera versión de la app iOS y Android.", ana, [dani])
project_for("Campaña de lanzamiento", "Plan de marketing para el lanzamiento de otoño.", ana, [marta])
project_for("Onboarding de clientes", "Proceso y materiales para nuevos clientes.", ana, [luis])

board = web.boards.first || web.boards.create!(title: "Tablero principal")
cols = board.columns.index_by(&:kind)
review = board.columns.find_or_create_by!(title: "En revisión") { |c| c.kind = "custom" }

lists = {
  "Diseño" => [
    ["Moodboard y referencias visuales", "done", [marta]],
    ["Wireframes de la home", "done", [marta, ana]],
    ["Diseño UI de páginas de producto", "in_progress", [marta]],
    ["Sistema de componentes en Figma", "review", [marta, luis]],
    ["Ilustraciones para la sección de equipo", "pending", [marta]],
  ],
  "Desarrollo" => [
    ["Configurar entorno y CI", "done", [luis]],
    ["Maquetar la home responsive", "in_progress", [luis, dani]],
    ["Integrar el CMS de blog", "pending", [dani]],
    ["Formulario de contacto con validaciones", "review", [luis]],
    ["Optimizar imágenes y Core Web Vitals", "pending", [dani]],
  ],
  "Contenido" => [
    ["Textos de la página Sobre nosotros", "in_progress", [ana]],
    ["Casos de éxito (3 clientes)", "pending", [ana, marta]],
    ["Revisión SEO de títulos y metas", "pending", [luis]],
  ]
}
lists.each_with_index do |(name, tasks), i|
  todo = web.todos.find_or_create_by!(name: name)
  tasks.each_with_index do |(title, st, people), j|
    t = todo.tasks.find_or_initialize_by(title: title)
    t.created_by ||= ana
    if st == "review"
      t.column = review
    else
      t.status = st
    end
    t.due_date ||= (j + i * 2 + 1).days.from_now.change(hour: 10)
    t.notes = "<p>Detalles de <strong>#{title.downcase}</strong>. Ver referencias en la carpeta de Diseño.</p><ul><li>Revisar con el equipo</li><li>Validar en móvil</li></ul>" if t.new_record?
    t.save!
    people.each { |u| TaskAssignment.find_or_create_by!(task: t, user: u) }
  end
end

hero = Task.find_by(title: "Maquetar la home responsive")
[[luis, "Ya tengo la estructura base, mañana subo la versión móvil 📱"],
 [marta, "¡Genial! Recuerda usar los tokens de color del sistema de componentes."],
 [ana, "Perfecto, lo revisamos el jueves en la reunión."]].each do |u, c|
  hero.comments.create!(user: u, content: c)
end if hero.comments.empty?

# Carpetas y documentos
f_design = web.folders.find_or_create_by!(name: "Diseño") { |f| f.created_by = marta }
f_brief  = web.folders.find_or_create_by!(name: "Briefs y propuestas") { |f| f.created_by = ana }
f_legal  = web.folders.find_or_create_by!(name: "Legal") { |f| f.created_by = ana }
web.folders.find_or_create_by!(name: "Recursos de marca") { |f| f.created_by = marta }
docs = [
  ["Brief del proyecto", nil, "<h1>Brief del proyecto</h1><p>Objetivo: renovar la web corporativa para mejorar la conversión y reflejar la nueva identidad de marca.</p><h2>Alcance</h2><ul><li>Home y páginas de producto</li><li>Blog con CMS</li><li>Formulario de contacto</li></ul>"],
  ["Guía de estilo", nil, "<h1>Guía de estilo</h1><p>Tipografías, colores y tono de voz para todas las piezas.</p><h2>Colores</h2><p>Primario, secundario y neutros.</p>"],
  ["Acta reunión de kickoff", nil, "<h1>Acta de kickoff</h1><p><strong>Asistentes:</strong> Ana, Luis, Marta, Daniel.</p><ol><li>Calendario de entregas</li><li>Responsables por área</li><li>Siguientes pasos</li></ol>"],
  ["Plan de contenidos", nil, "<h1>Plan de contenidos</h1><p>Calendario editorial del primer trimestre tras el lanzamiento.</p>"],
  ["Propuesta económica", f_brief, "<h1>Propuesta económica</h1><p>Desglose por fases del proyecto.</p>"],
]
docs.each do |name, folder, body|
  d = web.documents.find_or_initialize_by(name: name)
  d.created_by ||= ana
  d.folder = folder
  d.body = body
  d.status = "published"
  d.save!
end

# Chat
general = web.channels.find_or_create_by!(name: "general") { |c| c.creator = ana }
team.each { |u| ChannelMembership.find_or_create_by!(channel: general, user: u) }
if general.messages.empty?
  [[ana, "¡Buenos días equipo! 👋 Hoy cerramos el diseño de la home."],
   [marta, "Subí la última versión de los componentes a la carpeta de Diseño."],
   [luis, "Genial, empiezo a maquetar con eso. **¿Alguien revisa el formulario de contacto?**"],
   [dani, "Yo me encargo esta tarde 💪"],
   [ana, "Gracias a todos, vamos muy bien con los plazos 🚀"]].each_with_index do |(u, b), i|
    m = general.messages.create!(user: u, body: b)
    m.update_columns(created_at: (50 - i * 10).minutes.ago)
  end
end
web.channels.find_or_create_by!(name: "diseño") { |c| c.creator = marta }
web.channels.find_or_create_by!(name: "desarrollo") { |c| c.creator = luis }

web.announcements.create!(content: "🎉 Lanzamos la beta de la nueva web el próximo lunes. ¡Gracias a todo el equipo!") if web.announcements.empty?

puts "OK project=#{web.id} board=#{board.id} task=#{hero.id} todo=#{hero.todo_id} channel=#{general.id}"

# Coloca cada tarea en la columna del tablero según su estado
kind_for = { "pending" => "todo", "in_progress" => "in_progress", "done" => "done" }
Task.joins(:todo).where(todos: { project_id: web.id }, column_id: nil).find_each do |t|
  t.update!(column: cols[kind_for[t.status]])
end
