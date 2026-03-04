import { Routes } from '@angular/router';
import { TemplatesComponent } from './pages/templates/templates.component';
import { ResourcesComponent } from './pages/resources/resources.component';
import { TicketsComponent } from './pages/tickets/tickets.component';

export const routes: Routes = [
  { path: '', redirectTo: '/resources', pathMatch: 'full' },
  { path: 'templates', component: TemplatesComponent },
  { path: 'resources', component: ResourcesComponent },
  { path: 'tickets', component: TicketsComponent }
];
