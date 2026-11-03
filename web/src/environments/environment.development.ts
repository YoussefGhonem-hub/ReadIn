import { AppEnvironment } from './environment.model';

/**
 * Local development: API on :5080 and the Firebase Emulator Suite (`firebase emulators:start`), never the real
 * project. The emulator has no Cloud Messaging, so web push is off here.
 */
export const environment: AppEnvironment = {
  production: false,
  siteUrl: 'http://localhost:4200',
  apiBaseUrl: 'http://localhost:5080/api/v1',
  assetsBaseUrl: 'http://localhost:5080',
  firebase: {
    apiKey: 'demo-api-key',
    authDomain: 'demo-readin.firebaseapp.com',
    projectId: 'demo-readin',
    appId: 'demo-app-id',
    // Namespace `demo-readin`, the same one the API writes to (`?ns=demo-readin`).
    databaseURL: 'https://demo-readin.firebaseio.com',
    messagingSenderId: '0',
  },
  firebaseVapidKey: null,
  databaseEmulatorHost: '127.0.0.1:9000',
  authEmulatorUrl: 'http://127.0.0.1:9099',
  supportEmail: 'support@readin.app',
  googleWebClientId: '56680910112-11fpmt15shbi4mddnkjtuemfrdoqrp6e.apps.googleusercontent.com',
  appleServicesId: '',
};
