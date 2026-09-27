/**
 * MenShop Backend - Main Entry Point
 * Architecture: Model-View-ViewModel (MVVM)
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distAppPath = path.join(__dirname, 'dist', 'views', 'app.js');

if (!fs.existsSync(distAppPath)) {
  console.error('[MenShop Backend] Chua tim thay thu muc dist/. Vui long chay: npm run build');
  process.exit(1);
}

const { createApp } = await import('./dist/views/app.js');
const { env } = await import('./dist/config/env.js');

const app = createApp();

const server = app.listen(env.PORT, () => {
  console.log(`[MenShop Backend - MVVM] Server running at http://localhost:${env.PORT}`);
  console.log(`[MenShop Backend - MVVM] Architecture: Model-View-ViewModel`);
  console.log(`[MenShop Backend - MVVM] Health check: http://localhost:${env.PORT}/health`);
  console.log(`[MenShop Backend - MVVM] API Base: http://localhost:${env.PORT}/api/v1`);
});

export default server;
