import { defineConfig } from 'vite'

export default defineConfig({
  // Base path for GitHub Pages (or root for custom domain)
  base: process.env.VITE_BASE || '/',

  build: {
    outDir: 'dist',
    emptyOutDir: true,

    // Optimize for production
    minify: 'terser',
    sourcemap: false,

    rollupOptions: {
      output: {
        // Better caching with content hashes
        entryFileNames: 'assets/[name].[hash].js',
        chunkFileNames: 'assets/[name].[hash].js',
        assetFileNames: 'assets/[name].[hash].[ext]'
      }
    }
  },

  // Use environment variables for configuration
  define: {
    __API_URL__: JSON.stringify(process.env.VITE_API_URL || 'http://localhost:3001'),
    __ENV__: JSON.stringify(process.env.VITE_ENVIRONMENT || 'development'),
    __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
    __ANALYTICS_ID__: JSON.stringify(process.env.VITE_ANALYTICS_ID || ''),
  }
})
