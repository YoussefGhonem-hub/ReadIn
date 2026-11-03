/** The browser's IANA time zone, e.g. "Africa/Cairo" (the API's default when it can't be read). */
export function localTimeZone(): string {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone || 'Africa/Cairo';
  } catch {
    return 'Africa/Cairo';
  }
}
