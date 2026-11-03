import { HttpClient, HttpContext } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { API_BASE_URL, SILENT_ERRORS } from './api.config';
import { FieldDto, TopicDto } from './models';

@Injectable({ providedIn: 'root' })
export class TaxonomyApi {
  private readonly http = inject(HttpClient);
  private readonly base = inject(API_BASE_URL);

  fields(): Observable<FieldDto[]> {
    return this.http.get<FieldDto[]>(`${this.base}/fields`, { context: new HttpContext().set(SILENT_ERRORS, true) });
  }

  topics(fieldSlug: string): Observable<TopicDto[]> {
    return this.http.get<TopicDto[]>(`${this.base}/fields/${encodeURIComponent(fieldSlug)}/topics`, {
      context: new HttpContext().set(SILENT_ERRORS, true),
    });
  }
}
