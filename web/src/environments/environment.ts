import { AppEnvironment } from './environment.model';

/** Production defaults. Firebase values are injected by the deploy pipeline (staging/prod Firebase projects). */
export const environment: AppEnvironment = {
  production: true,
  siteUrl: 'https://readin.app',
  apiBaseUrl: 'https://api.readin.app/api/v1',
  assetsBaseUrl: 'https://storage.googleapis.com/readin-prod.appspot.com',
  firebase: {
    apiKey: 'REPLACE_IN_CI',
    authDomain: 'readin-prod.firebaseapp.com',
    projectId: 'readin-prod',
    appId: 'REPLACE_IN_CI',
  },
  authEmulatorUrl: null,
};
