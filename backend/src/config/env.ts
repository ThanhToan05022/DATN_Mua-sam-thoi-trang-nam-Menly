import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { z } from 'zod';
import dotenv from 'dotenv';

dotenv.config({ path: path.resolve(fileURLToPath(new URL('../../../.env', import.meta.url))) });
dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().default(5000),
  SUPABASE_URL: z.string().url().default('https://lihnuaymkrwmgdspnkux.supabase.co'),
  SUPABASE_ANON_KEY: z.string().default('sb_publishable_QayBQo9iCpdtkNg16h6EFQ_m_DD8vXs'),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional().default(''),
  VNPAY_TMN_CODE: z.string().default('DEMOMENSHOP'),
  VNPAY_HASH_SECRET: z.string().default('SECRETKEYFORSANDBOXTESTING1234567890'),
  VNPAY_PAY_URL: z.string().url().default('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'),
  VNPAY_RETURN_URL: z.string().url().default('http://localhost:5000/api/v1/payments/vnpay/return'),
  USE_MOCK_DB: z.string().transform((val) => val === 'true').default('false'),
});

export const env = envSchema.parse(process.env);
export type Env = z.infer<typeof envSchema>;
