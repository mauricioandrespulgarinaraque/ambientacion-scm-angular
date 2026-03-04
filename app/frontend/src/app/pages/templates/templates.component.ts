import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ApiService } from '../../services/api.service';

@Component({
  selector: 'app-templates',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './templates.component.html',
  styleUrls: ['./templates.component.css']
})
export class TemplatesComponent implements OnInit {
  templates: any[] = [];
  isCreating = false;
  editingId: string | null = null;
  loading = false;
  message = '';
  messageType = '';

  formData = {
    name: '',
    provider: 'GCP',
    resource_type: 'VM',
    content: ''
  };

  resourceTypes: any = {
    GCP: ['VM', 'GKE', 'GAR', 'STORAGE', 'SQL'],
    Azure: ['VM', 'AKS', 'ACR', 'BLOB', 'SQL']
  };

  constructor(private apiService: ApiService) { }

  ngOnInit() {
    this.fetchTemplates();
  }

  fetchTemplates() {
    this.loading = true;
    this.apiService.getTemplates().subscribe(
      (data: any) => {
        this.templates = data;
        this.loading = false;
      },
      (error: any) => {
        console.error('Error al cargar plantillas', error);
        this.loading = false;
      }
    );
  }

  handleCreate() {
    this.isCreating = true;
    this.resetForm();
  }

  handleEdit(template: any) {
    this.editingId = template.id;
    this.formData = { ...template };
  }

  handleCancel() {
    this.isCreating = false;
    this.editingId = null;
    this.resetForm();
  }

  resetForm() {
    this.formData = {
      name: '',
      provider: 'GCP',
      resource_type: 'VM',
      content: ''
    };
  }

  handleSave() {
    if (!this.formData.name || !this.formData.content) {
      this.setMessage('Por favor completa todos los campos', 'error');
      return;
    }

    if (this.editingId) {
      this.apiService.updateTemplate(this.editingId, this.formData).subscribe(
        () => {
          this.setMessage('Plantilla actualizada', 'success');
          this.handleCancel();
          this.fetchTemplates();
        },
        (error: any) => {
          console.error('Error al actualizar', error);
          this.setMessage('Error al actualizar plantilla', 'error');
        }
      );
    } else {
      this.apiService.createTemplate(this.formData).subscribe(
        () => {
          this.setMessage('Plantilla creada', 'success');
          this.handleCancel();
          this.fetchTemplates();
        },
        (error: any) => {
          console.error('Error al crear', error);
          this.setMessage('Error al crear plantilla', 'error');
        }
      );
    }
  }

  handleDelete(id: string) {
    if (confirm('¿Eliminar plantilla?')) {
      this.apiService.deleteTemplate(id).subscribe(
        () => {
          this.setMessage('Plantilla eliminada', 'success');
          this.fetchTemplates();
        },
        (error: any) => {
          console.error('Error al eliminar', error);
          this.setMessage('Error al eliminar plantilla', 'error');
        }
      );
    }
  }

  setMessage(msg: string, type: string) {
    this.message = msg;
    this.messageType = type;
    setTimeout(() => {
      this.message = '';
    }, 3000);
  }

  onProviderChange(provider: string) {
    this.formData.provider = provider;
    this.formData.resource_type = this.resourceTypes[provider][0];
  }

  get currentResourceTypes() {
    return this.resourceTypes[this.formData.provider];
  }
}
