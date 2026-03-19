/// <reference types="vitest/config" />
import {defineConfig} from 'vite';
import react from '@vitejs/plugin-react';
import {TanStackRouterVite} from '@tanstack/router-plugin/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [TanStackRouterVite({routeFileIgnorePattern: '\\.(test|spec)\\.(tsx?|jsx?)$'}), react()],
  server: {
    port: 8091,
    host: true,
    watch: {
      usePolling: true,
      ignored: ['**/node_modules/**', '**/.git/**'],
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
  },
});
