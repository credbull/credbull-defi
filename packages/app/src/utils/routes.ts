export const Routes = {
  LOGIN: '/login',
  REGISTER: '/register',
  FORGOT_PASSWORD: '/forgot-password',
  UPDATE_PASSWORD: '/update-password',
  CODE_CALLBACK: '/code/callback',
  MAGIC_LINK: '/magic-link',
  DASHBOARD: '/dashboard',
  HOME: '/',
} as const;

export const Segments = {
  PROTECTED: '(protected)',
} as const;
