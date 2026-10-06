import { Router } from 'express';
import { SupabaseClient } from '@supabase/supabase-js';

export const healthRoutes = (supabase?: SupabaseClient): Router => {
  const router = Router();

  router.get('/', async (_req, res) => {
    let dbStatus = 'not_configured';

    if (supabase) {
      try {
        const { error } = await supabase.from('categories').select('id').limit(1);
        dbStatus = error ? `error: ${error.message}` : 'healthy';
      } catch (err: unknown) {
        dbStatus = `unreachable: ${err instanceof Error ? err.message : String(err)}`;
      }
    }

    res.json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: dbStatus,
    });
  });

  return router;
};
