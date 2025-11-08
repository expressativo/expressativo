import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["source", "button"];

  copy(event) {
    event.preventDefault();
    
    const text = this.sourceTarget.value;
    const button = this.hasButtonTarget ? this.buttonTarget : event.currentTarget;
    
    navigator.clipboard.writeText(text).then(() => {
      this.showSuccess(button);
    }).catch(err => {
      console.error('Error al copiar:', err);
      this.showError();
    });
  }

  showSuccess(button) {
    const originalText = button.textContent;
    const originalClasses = button.className;
    
    button.textContent = '¡Copiado!';
    button.classList.add('bg-green-600', 'text-white');
    
    setTimeout(() => {
      button.textContent = originalText;
      button.className = originalClasses;
    }, 2000);
  }

  showError() {
    alert('Error al copiar el link. Por favor, cópialo manualmente.');
  }
}
