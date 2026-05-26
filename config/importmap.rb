# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "lexical", to: "https://esm.sh/lexical@0.21.0?target=es2022"
pin "@lexical/rich-text", to: "https://esm.sh/@lexical/rich-text@0.21.0?deps=lexical@0.21.0&target=es2022"
pin "@lexical/list", to: "https://esm.sh/@lexical/list@0.21.0?deps=lexical@0.21.0&target=es2022"
pin "@lexical/history", to: "https://esm.sh/@lexical/history@0.21.0?deps=lexical@0.21.0&target=es2022"
pin "@lexical/html", to: "https://esm.sh/@lexical/html@0.21.0?deps=lexical@0.21.0&target=es2022"
pin "@lexical/code", to: "https://esm.sh/@lexical/code@0.21.0?deps=lexical@0.21.0&target=es2022"
pin "sortablejs" # @1.15.6
pin "html2canvas" # @1.4.1
pin "tributejs" # @5.1.3
pin "glightbox", to: "https://esm.sh/glightbox@3.3.1"
pin "emoji-picker-element", to: "https://cdn.jsdelivr.net/npm/emoji-picker-element@1/index.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
