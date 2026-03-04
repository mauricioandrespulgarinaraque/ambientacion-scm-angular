import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private apiUrl = '/api';

  constructor(private http: HttpClient) { }

  // Templates
  getTemplates(): Observable<any> {
    return this.http.get(`${this.apiUrl}/templates`);
  }

  getTemplate(id: string): Observable<any> {
    return this.http.get(`${this.apiUrl}/templates/${id}`);
  }

  createTemplate(data: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/templates`, data);
  }

  updateTemplate(id: string, data: any): Observable<any> {
    return this.http.put(`${this.apiUrl}/templates/${id}`, data);
  }

  deleteTemplate(id: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/templates/${id}`);
  }

  // Resources
  getResources(): Observable<any> {
    return this.http.get(`${this.apiUrl}/resources`);
  }

  // Tickets
  generateTicket(resourceIds: string[]): Observable<any> {
    return this.http.post(`${this.apiUrl}/tickets/generate`, { resource_ids: resourceIds });
  }

  getTickets(): Observable<any> {
    return this.http.get(`${this.apiUrl}/tickets`);
  }

  getTicket(id: string): Observable<any> {
    return this.http.get(`${this.apiUrl}/tickets/${id}`);
  }
}
