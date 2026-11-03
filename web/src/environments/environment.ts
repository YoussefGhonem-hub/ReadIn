import { AppEnvironment } from './environment.model';

/**
 * Production build: the single real Firebase project `readin-cca78` (ADR 0005), used only for web push and the
 * Realtime Database. These are public client identifiers, not secrets; access is enforced by
 * `firebase/database.rules.json`.
 */
export const environment: AppEnvironment = {
  production: true,
  siteUrl: 'https://readin.app',
  apiBaseUrl: 'https://api.readin.app/api/v1',
  assetsBaseUrl: 'https://api.readin.app',
  firebase: {
    apiKey: 'AIzaSyDBpEBFi3QewssqF-jftxgjd3G-5BqfnXs',
    authDomain: 'readin-cca78.firebaseapp.com',
    projectId: 'readin-cca78',
    appId: '1:56680910112:web:7ca9692de24acca4ba9b45',
    databaseURL: 'https://readin-cca78-default-rtdb.europe-west1.firebasedatabase.app',
    messagingSenderId: '56680910112',
  },
  firebaseVapidKey: 'BII3t6QLmXvySejsMKG9iz9lZpFqFRwDitQuTPq8RkukKfRCuoQ5_ChkH1zCdKlgF525LBs0yRtqUGEecNuN_YQ',
  databaseEmulatorHost: null,
  authEmulatorUrl: null,
  supportEmail: 'youssef.fcaih@gmail.com',
  accountDeletionUrl: 'https://readin-cca78.firebaseapp.com/delete-account',
  googleWebClientId: '56680910112-11fpmt15shbi4mddnkjtuemfrdoqrp6e.apps.googleusercontent.com',
  appleServicesId: '',
};
