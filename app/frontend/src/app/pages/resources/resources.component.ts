import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { ApiService } from '../../services/api.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-resources',
  standalone: true,
  imports: [CommonModule, RouterModule],
  templateUrl: './resources.component.html',
  styleUrls: ['./resources.component.css']
})
export class ResourcesComponent implements OnInit {
  resources: any[] = [];
  templates: any[] = [];
  selectedResources: string[] = [];
  loading = false;
  generating = false;
  message = '';
  messageType = '';

  constructor(private apiService: ApiService, private router: Router) { }

  ngOnInit() {
    this.fetchResources();
    this.fetchTemplates();
  }

  fetchResources() {
    this.loading = true;
    this.apiService.getResources().subscribe(
      (data: any) => {
        this.resources = data;
        this.loading = false;
      },
      (error: any) => {
        console.error('Error al cargar recursos', error);
        this.setMessage('Error al cargar recursos', 'error');
        this.loading = false;
      }
    );
  }

  fetchTemplates() {
    this.apiService.getTemplates().subscribe(
      (data: any) => {
        this.templates = data;
      },
      (error: any) => {
        console.warn('Error al cargar plantillas', error);
      }
    );
  }

  toggleResource(resourceId: string) {
    const index = this.selectedResources.indexOf(resourceId);
    if (index === -1) {
      this.selectedResources.push(resourceId);
    } else {
      this.selectedResources.splice(index, 1);
    }
  }

  isSelected(resourceId: string): boolean {
    return this.selectedResources.includes(resourceId);
  }

  handleGenerateTicket() {
    if (this.selectedResources.length === 0) {
      this.setMessage('Selecciona al menos un recurso', 'error');
      return;
    }

    this.generating = true;
    this.apiService.generateTicket(this.selectedResources).subscribe(
      () => {
        this.setMessage('Ticket generado exitosamente', 'success');
        this.selectedResources = [];
        setTimeout(() => {
          this.router.navigate(['/tickets']);
        }, 1000);
      },
      (error: any) => {
        console.error('Error al generar ticket', error);
        this.setMessage('Error al generar ticket', 'error');
        this.generating = false;
      }
    );
  }

  setMessage(msg: string, type: string) {
    this.message = msg;
    this.messageType = type;
    setTimeout(() => {
      this.message = '';
    }, 3000);
  }

  getTemplateForResource(resource: any): any {
    const rt = resource.id.split('-')[1]?.toUpperCase() || '';
    return this.templates.find(t => t.provider === resource.provider && t.resource_type === rt);
  }

  get gcpResources() {
    return this.resources.filter(r => r.provider === 'GCP');
  }

  get azureResources() {
    return this.resources.filter(r => r.provider === 'Azure');
  }
}
