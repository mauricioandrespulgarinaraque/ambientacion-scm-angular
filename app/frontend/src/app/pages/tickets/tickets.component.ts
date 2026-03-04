import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService } from '../../services/api.service';

interface Ticket {
  id: string;
  resources: any;
  consolidated_content: string;
  created_at: string;
}

@Component({
  selector: 'app-tickets',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './tickets.component.html',
  styleUrls: ['./tickets.component.css']
})
export class TicketsComponent implements OnInit {
  tickets: Ticket[] = [];
  loading = false;
  error = '';
  selectedTicketId: string | null = null;
  copiedMessage = '';

  constructor(private apiService: ApiService) {}

  ngOnInit() {
    this.loadTickets();
  }

  loadTickets() {
    this.loading = true;
    this.error = '';
    this.apiService.getTickets().subscribe({
      next: (data) => {
        this.tickets = data;
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Error loading tickets: ' + err.message;
        this.loading = false;
      }
    });
  }

  toggleTicketDetail(id: string) {
    if (this.selectedTicketId === id) {
      this.selectedTicketId = null;
    } else {
      this.selectedTicketId = id;
    }
  }

  getResourceSummary(ticket: Ticket): string {
    try {
      const resources = typeof ticket.resources === 'string'
        ? JSON.parse(ticket.resources)
        : ticket.resources;
      return Array.isArray(resources)
        ? resources.map((r: any) => `${r.provider}/${r.resource_type}`).join(', ')
        : 'Unknown resources';
    } catch (e) {
      return 'Unknown resources';
    }
  }

  formatDate(dateString: string): string {
    try {
      const date = new Date(dateString);
      return date.toLocaleString();
    } catch (e) {
      return dateString;
    }
  }

  copyToClipboard(content: string) {
    navigator.clipboard.writeText(content).then(() => {
      this.copiedMessage = 'Copied to clipboard!';
      setTimeout(() => {
        this.copiedMessage = '';
      }, 2000);
    }).catch(err => {
      this.error = 'Failed to copy: ' + err.message;
    });
  }

  handleRefresh() {
    this.selectedTicketId = null;
    this.loadTickets();
  }
}
