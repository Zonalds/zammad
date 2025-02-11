// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const colors = require('tailwindcss/colors')
const formKitTailwind = require('@formkit/themes/tailwindcss')
const path = require('path')
const zammadTailwind = require('../../../build/zammadTailwindPlugin.js')

const mobileDir = path.resolve(__dirname, '..')
const sharedDir = path.resolve(__dirname, '../../../shared')

module.exports = {
  content: [
    `${mobileDir}/**/*.{js,jsx,ts,tsx,vue}`,
    `${sharedDir}/**/*.{js,jsx,ts,tsx,vue}`,
  ],
  plugins: [
    formKitTailwind,
    zammadTailwind,
    ({ addComponents, theme }) => {
      addComponents({
        // NB: Used by FieldDateTimeInput.vue component, within its style section.
        //   Since all component styles are processed in isolation, we have to provide the classes below within the
        //   configuration, otherwise we risk running into build issues since class definitions in imported stylesheets
        //   might not be available.
        '.date-selection': {
          borderColor: theme('colors.blue.DEFAULT'),
          backgroundColor: theme('colors.blue.DEFAULT'),
          backgroundImage: 'none',
        },
        '.date-navigation': {
          color: theme('colors.blue.DEFAULT'),
        },
      })
    },
  ],
  theme: {
    colors: {
      pink: {
        DEFAULT: '#EA4D84',
        bright: '#FF006B',
      },
      black: {
        DEFAULT: '#191919',
        full: colors.black,
      },
      white: colors.white,
      gray: {
        DEFAULT: '#999999',
        100: '#D1D1D1',
        150: '#D8D8D8',
        200: '#656567',
        300: '#4C4C4D',
        400: '#323234',
        500: '#282829',
        600: '#262627',
        highlight: '#99999926',
        light: '#25262D99',
      },
      blue: {
        DEFAULT: '#23A2CD',
        dark: '#045972',
        highlight: '#23A2CD19',
      },
      yellow: {
        DEFAULT: '#FFCE33',
        highlight: '#FFCE331A',
        inactive: '#A38629',
      },
      red: {
        DEFAULT: '#E54011',
        highlight: '#E540111A',
        bright: '#FF4008',
        dark: '#261F1D',
      },
      green: {
        DEFAULT: '#36AF6A',
        highlight: '#38AD691A',
      },
      orange: '#F39804',
    },
  },
}
