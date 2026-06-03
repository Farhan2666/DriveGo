/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: { DEFAULT: '#2563EB', 50: '#EFF6FF', 100: '#DBEAFE', 200: '#BFDBFE', 500: '#2563EB', 600: '#2563EB', 700: '#1D4ED8' },
        secondary: '#F59E0B',
        accent: '#10B981',
      },
    },
  },
  plugins: [],
};
