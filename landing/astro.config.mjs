import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://dualio.app',
  trailingSlash: 'never',
  build: {
    format: 'file',
  },
});
