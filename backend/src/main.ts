import { createApp } from './views/app.js';
import { env } from './config/env.js';

const app = createApp();

app.listen(env.PORT, () => {
  console.log(`[MenShop Backend - MVVM] Server running at http://localhost:${env.PORT}`);
  console.log(`[MenShop Backend - MVVM] Architecture: Model-View-ViewModel`);
  console.log(`[MenShop Backend - MVVM] Health check: http://localhost:${env.PORT}/health`);
  console.log(`[MenShop Backend - MVVM] API Base: http://localhost:${env.PORT}/api/v1`);
});
