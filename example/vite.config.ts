import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import topLevelAwait from 'vite-plugin-top-level-await';
import {nodePolyfills} from 'vite-plugin-node-polyfills';

export default defineConfig({
  plugins: [react(), topLevelAwait(), nodePolyfills({ include: ['buffer'] })],
  build: {
    watch: {
      include: ['../js/dist/**/*.js']
    }
  }
})
