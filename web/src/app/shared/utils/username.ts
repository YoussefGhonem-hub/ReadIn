import { Observable, catchError, debounceTime, distinctUntilChanged, map, of, startWith, switchMap } from 'rxjs';
import { UsernameAvailabilityDto } from '../../core/api/models';

export const USERNAME_PATTERN = /^[a-z0-9_]{3,30}$/;
export const USERNAME_DEBOUNCE_MS = 400;

export type UsernameStatus = 'idle' | 'invalid' | 'checking' | 'available' | 'taken' | 'error';

/** Lower-cases and drops what a handle can't contain, so "Mona Adel" becomes "monaadel" as it's typed. */
export function normalizeUsername(value: string): string {
  return value.trim().replace(/^@/, '').toLowerCase().replace(/[^a-z0-9_]/g, '').slice(0, 30);
}

/**
 * The live @username check (complete profile, edit profile): format first, then `GET /users/username-available` after
 * a pause in typing. Your own handle counts as available.
 */
export function usernameStatus(
  values: Observable<string>,
  available: (username: string) => Observable<UsernameAvailabilityDto>,
  debounceMs = USERNAME_DEBOUNCE_MS,
): Observable<UsernameStatus> {
  return values.pipe(
    map((username) => username.trim()),
    distinctUntilChanged(),
    switchMap((username) => {
      if (!username) return of<UsernameStatus>('idle');
      if (!USERNAME_PATTERN.test(username)) return of<UsernameStatus>('invalid');
      return of(username).pipe(
        debounceTime(debounceMs),
        switchMap((u) => available(u)),
        map((result): UsernameStatus => (!result.valid ? 'invalid' : result.available ? 'available' : 'taken')),
        catchError(() => of<UsernameStatus>('error')),
        startWith<UsernameStatus>('checking'),
      );
    }),
  );
}
