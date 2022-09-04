const round = (num) =>
  num
    .toFixed(7)
    .replace(/(\.[0-9]+?)0+$/, '$1')
    .replace(/\.0$/, '');
const rem = (px) => `${round(px / 16)}rem`;
const em = (px, base) => `${round(px / base)}em`;

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/views/**/*.turbo_stream.erb',
    './app/components/**/*.html.erb',
    './app/components/**/*.js',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
  ],
  darkMode: 'class',
  theme: {
    backgroundColor: (theme) => ({
      ...theme('colors'),
      dark: '#1b1c1e',
      primary: '#5C6BEF',
    }),
    textColor: (theme) => ({
      ...theme('colors'),
      primary: '#5C6BEF',
    }),
    borderColor: (theme) => ({
      ...theme('colors'),
      primary: '#5C6BEF',
    }),
    extend: {
      minWidth: {
        1: '0.25rem',
        2: '0.5rem',
        4: '1rem',
        8: '2rem',
        16: '4rem',
        32: '8rem',
        64: '16rem',
        72: '18rem',
        80: '20rem',
        96: '24rem',
        md: '28rem',
        lg: '32rem',
        xl: '36rem',
        '2xl': '42rem',
      },
      minHeight: {
        'screen-1/2': '50vh',
        'screen-1/3': '33vh',
        'screen-2/3': '67vh',
        'screen-1/4': '25vh',
        'screen-3/4': '75vh',
        screen: '100vh',
        1: '0.25rem',
        2: '0.5rem',
        4: '1rem',
        8: '2rem',
        16: '4rem',
        32: '8rem',
        64: '16rem',
        72: '18rem',
        80: '20rem',
        96: '24rem',
      },
      maxHeight: {
        'screen-1/2': '50vh',
        'screen-1/3': '33vh',
        'screen-2/3': '67vh',
        'screen-1/4': '25vh',
        'screen-3/4': '75vh',
        screen: '100vh',
      },
      typography: {
        DEFAULT: {
          css: {
            blockquote: {
              quotes: '',
            },
            'blockquote p:first-of-type::before': {
              content: 'none',
            },
            'blockquote p:last-of-type::after': {
              content: 'none',
            },
            code: {
              color: 'inherit',
              backgroundColor: 'var(--tw-prose-pre-code)',
              fontWeight: '600',
              borderRadius: rem(6),
              paddingTop: rem(0.8),
              paddingRight: rem(4.8),
              paddingBottom: rem(0.8),
              paddingLeft: rem(4.8),
            },
            'code::before': {
              content: 'none',
            },
            'code::after': {
              content: 'none',
            },
          },
        },
        invert: {
          css: {
            code: {
              color: 'inherit',
              backgroundColor: 'var(--tw-prose-pre-code)',
            }
          }
        }
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
    require('@tailwindcss/line-clamp'),
    require('@tailwindcss/forms'),
    require('tailwind-scrollbar-hide'),
  ],
};
