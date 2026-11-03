import { AppEnvironment } from './environment.model';

/** Local development: API on :5080 and the Firebase Auth emulator (`firebase emulators:start`). */
export const environment: AppEnvironment = {
  production: false,
  siteUrl: 'http://localhost:4200',
  apiBaseUrl: 'http://localhost:5080/api/v1',
  assetsBaseUrl: 'http://127.0.0.1:9199/v0/b/demo-readin.appspot.com/o',
  firebase: {
    apiKey: 'demo-api-key',
    authDomain: 'demo-readin.firebaseapp.com',
    projectId: 'demo-readin',
    appId: 'demo-app-id',
  },
  authEmulatorUrl: 'http://127.0.0.1:9099',
};
