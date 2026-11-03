import { Type } from '@angular/core';
import { DevLoginPanel } from './dev-login-panel';

/** Development builds only (angular.json → fileReplacements): the seed-user login panel (SPEC §18.3). */
export const DEV_LOGIN_PANEL: Type<unknown> | null = DevLoginPanel;
