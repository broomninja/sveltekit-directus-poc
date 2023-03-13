/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
            'src/**/*.{html,js,svelte,ts}',
            'node_modules/preline/dist/*.js',
        ],
  theme: {
    extend: {},
  },
  plugins: [
    require('preline/plugin'),
    require('@tailwindcss/line-clamp'),
  ],
}
