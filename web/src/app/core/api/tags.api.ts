import { HttpClient, HttpContext, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { TagDto } from './models';

/** Tag suggestions for the editor (F05). Only the editor uses it, so it stays out of the initial bundle. */
@Injectable({ providedIn: 'root' })
export class TagsApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  /** `GET /tags?q=&limit=` 🌐: tags whose name or slug starts with `q` (case-insensitive), most used first. */
  search(q: string, limit = 10): Observable<TagDto[]> {
    const params = new HttpParams().set('q', q).set('limit', String(limit));
    return this.http.get<TagDto[]>(`${this.base}/tags`, { params, context: new HttpContext().set(SILENT_ERRORS, true) });
  }
}
