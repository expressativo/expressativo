// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"



document.addEventListener("DOMContentLoaded", function () {
  const button = document.getElementById("mobile-menu-button");
  const menu = document.getElementById("mobile-menu");
  const iconOpen = button.querySelector("svg.block");
  const iconClose = button.querySelector("svg.hidden");

  button.addEventListener("click", function () {
    const isOpen = menu.classList.contains("block");

    // Toggle menu visibility
    menu.classList.toggle("hidden");
    menu.classList.toggle("block");

    // Toggle icons
    iconOpen.classList.toggle("hidden");
    iconOpen.classList.toggle("block");
    iconClose.classList.toggle("hidden");
    iconClose.classList.toggle("block");

    // Optionally update aria-expanded
    button.setAttribute("aria-expanded", !isOpen);
  });

  // Inicialmente ocultamos el menú en caso de que esté visible
  if (!menu.classList.contains("hidden")) {
    menu.classList.add("hidden");
  }
});

import "trix"
import "@rails/actiontext"
