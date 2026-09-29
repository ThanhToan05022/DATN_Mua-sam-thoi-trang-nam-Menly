import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import express, { RequestHandler } from 'express';
import request from 'supertest';
import { profileRoutes } from '../../src/views/routes/profile.routes.js';
import { errorHandler } from '../../src/presentation/http/middlewares/error-handler.js';

// ---- Supabase client gia lap ----
type ProfileRow = { email: string | null } | null;

function makeSupabase(profile: ProfileRow) {
  const single = vi.fn().mockResolvedValue({ data: profile, error: null });
  const select = vi.fn(() => ({ eq: vi.fn(() => ({ single })) }));
  const from = vi.fn(() => ({ select }));
  return {
    client: { from, supabaseUrl: 'https://demo.supabase.co' } as any,
    from,
  };
}

// Client anon dung de xac thuc mat khau hien tai
const signInWithPassword = vi.fn();

vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn((_url: string, _key: string, options?: any) => {
    // Neu co user token -> client de doi mat khau; nguoc lai -> client xac thuc
    if (options?.global?.headers?.Authorization) {
      return {
        auth: {
          updateUser: vi.fn().mockResolvedValue({ data: {}, error: null }),
        },
      };
    }
    return { auth: { signInWithPassword } };
  }),
}));

function buildApp(supabase: any, requireAuth: RequestHandler): express.Express {
  const app = express();
  app.use(express.json());
  app.use((req, _res, next) => {
    req.headers.authorization = 'Bearer real-supabase-jwt';
    next();
  });
  app.use('/api/v1/profile', profileRoutes(requireAuth, supabase));
  app.use(errorHandler);
  return app;
}

const passThroughAuth: RequestHandler = (req, _res, next) => {
  req.user = { id: 'user-uuid-1', role: 'customer' };
  next();
};

describe('POST /api/v1/profile/change-password', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('rejects a new password shorter than 6 characters', async () => {
    const { client } = makeSupabase({ email: 'kh@example.com' });
    const res = await request(buildApp(client, passThroughAuth))
      .post('/api/v1/profile/change-password')
      .send({ newPassword: 'abc' });

    expect(res.status).toBe(400);
    expect(signInWithPassword).not.toHaveBeenCalled();
  });

  it('rejects when currentPassword is missing', async () => {
    const { client } = makeSupabase({ email: 'kh@example.com' });
    const res = await request(buildApp(client, passThroughAuth))
      .post('/api/v1/profile/change-password')
      .send({ newPassword: 'newpass123' });

    expect(res.status).toBe(400);
    expect(signInWithPassword).not.toHaveBeenCalled();
  });

  it('returns 400 when the current password is wrong', async () => {
    signInWithPassword.mockResolvedValue({
      data: {},
      error: { message: 'Invalid login credentials' },
    });
    const { client } = makeSupabase({ email: 'kh@example.com' });
    const res = await request(buildApp(client, passThroughAuth))
      .post('/api/v1/profile/change-password')
      .send({ newPassword: 'newpass123', currentPassword: 'sai-mat-khau' });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toBe('Mật khẩu hiện tại không đúng');
    expect(signInWithPassword).toHaveBeenCalledWith({
      email: 'kh@example.com',
      password: 'sai-mat-khau',
    });
  });

  it('changes the password when the current password matches', async () => {
    signInWithPassword.mockResolvedValue({ data: {}, error: null });
    const { client } = makeSupabase({ email: 'kh@example.com' });
    const res = await request(buildApp(client, passThroughAuth))
      .post('/api/v1/profile/change-password')
      .send({ newPassword: 'newpass123', currentPassword: 'mat-khau-dung' });

    expect(res.status).toBe(200);
    expect(res.body.message).toBe('Đổi mật khẩu thành công');
  });

  it('skips verification when the profile has no email (mock mode)', async () => {
    const { client } = makeSupabase(null);
    const res = await request(buildApp(client, passThroughAuth))
      .post('/api/v1/profile/change-password')
      .send({ newPassword: 'newpass123', currentPassword: 'bat-ky' });

    expect(res.status).toBe(200);
    expect(signInWithPassword).not.toHaveBeenCalled();
  });
});
