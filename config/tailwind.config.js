/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
    "./app/components/**/*.{erb,haml,html,slim,rb}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
