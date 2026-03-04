# Ambientación 2 - FastAPI + Angular + PostgreSQL

A scalable template management and ticket generation system built with FastAPI backend, Angular frontend, and PostgreSQL database.

## Tech Stack

- **Backend**: FastAPI 0.110.1, SQLAlchemy 2.0.23, Psycopg2
- **Frontend**: Angular 17, RxJS 7.8 (no additional UI libraries)
- **Database**: PostgreSQL 15
- **Styling**: Plain CSS
- **Deployment**: Docker & Docker Compose

## Features

- **Template Management**: Create, edit, delete templates for different cloud providers (GCP/Azure) and resource types
- **Resource Selection**: Browse and select cloud resources from different providers
- **Ticket Generation**: Automatically generate tickets with consolidated template content
- **Plain CSS UI**: No external UI frameworks, minimal dependencies

## Project Structure

```
ambientacion-2/
├── app/
│   ├── backend/
│   │   ├── server.py              # FastAPI app with SQLAlchemy models
│   │   ├── requirements.txt       # Python dependencies
│   │   ├── .env                   # Database and CORS configuration
│   │   ├── Dockerfile            # Python 3.10 container
│   │   └── .dockerignore          # Docker exclude patterns
│   └── frontend/
│       ├── src/
│       │   ├── main.ts            # Angular bootstrap
│       │   ├── index.html         # Entry point
│       │   ├── styles.css         # Global styles
│       │   └── app/
│       │       ├── app.config.ts  # DI configuration
│       │       ├── app.routes.ts  # Route definitions
│       │       ├── app.component.* # Main layout
│       │       ├── services/
│       │       │   └── api.service.ts # HTTP client for API calls
│       │       └── pages/
│       │           ├── templates/   # Template CRUD
│       │           ├── resources/   # Resource selection
│       │           └── tickets/     # Ticket viewing
│       ├── package.json           # Dependencies
│       ├── angular.json           # CLI configuration
│       ├── tsconfig.json          # TypeScript config
│       ├── Dockerfile            # Multi-stage build for Nginx
│       ├── nginx.conf            # Nginx configuration
│       └── .dockerignore         # Docker exclude patterns
├── docker-compose.yml             # Compose orchestration
└── README.md                      # This file
```

## Local Development

### Prerequisites

- Python 3.10+
- Node.js 18+
- PostgreSQL 12+ (or use Docker)

### Backend Setup

1. Create Python virtual environment:
   ```bash
   cd app/backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Configure database connection in `.env`:
   ```
   DATABASE_URL=postgresql://user:password@localhost:5432/ambientacion2
   CORS_ORIGINS=http://localhost:3000
   ```

4. PostgreSQL Setup (if local):
   ```sql
   CREATE DATABASE ambientacion2;
   CREATE USER admin WITH PASSWORD 'password';
   GRANT ALL PRIVILEGES ON DATABASE ambientacion2 TO admin;
   ```

5. Run backend server:
   ```bash
   python -m uvicorn server:app --reload --port 8001
   ```
   Server will be available at `http://localhost:8001`

### Frontend Setup

1. Install dependencies:
   ```bash
   cd app/frontend
   npm install
   ```

2. Start development server:
   ```bash
   npm start
   ```
   Frontend will be available at `http://localhost:4200`

## API Endpoints

All endpoints return JSON. Base URL: `http://localhost:8001/api`

### Templates
- `GET /api/templates` - List all templates
- `POST /api/templates` - Create new template
- `PUT /api/templates/{id}` - Update template
- `DELETE /api/templates/{id}` - Delete template

### Resources
- `GET /api/resources` - Get available GCP and Azure resources

### Tickets
- `POST /api/tickets/generate` - Generate ticket from selected resources
- `GET /api/tickets` - List all generated tickets
- `GET /api/tickets/{id}` - Get ticket details

## Docker Deployment

### Build and Run

```bash
docker-compose up --build
```

This will start:
- **PostgreSQL**: Port 5432
- **Backend**: Port 8001
- **Frontend**: Port 3000

Access the app at `http://localhost:3000`

### Services

Services communicate via Docker network:
- Frontend at `http://frontend:3000`
- Backend at `http://backend:8001`
- Database connection string: `postgresql://admin:password@postgres:5432/ambientacion2`

### Environment Variables (docker-compose)

Edit `docker-compose.yml` to change:
- `POSTGRES_DB`: Database name (default: `ambientacion2`)
- `POSTGRES_USER`: Database user (default: `admin`)
- `POSTGRES_PASSWORD`: Database password (default: `password`)
- `DATABASE_URL`: Connection string in backend service
- `CORS_ORIGINS`: Allowed origins for backend CORS

## Database Models

### Template

```
id (String, Primary Key)
name (String)
provider (String)         # "GCP" or "AZURE"
resource_type (String)    # Normalized to uppercase
content (String)
created_at (DateTime)
```

### Ticket

```
id (String, Primary Key)
resources (String)        # JSON array of selected resources
consolidated_content (String)  # Combined template content
created_at (DateTime)
```

## GCP Resources

- **Compute Engine**: Virtual Machines
- **GKE**: Kubernetes Engine
- **GAR**: Artifact Registry
- **Cloud Storage**: Storage buckets
- **Cloud SQL**: SQL database service

## Azure Resources

- **Virtual Machines**: Compute instances
- **AKS**: Kubernetes Service
- **ACR**: Container Registry
- **Blob Storage**: Object storage
- **Azure SQL**: Database service

## Troubleshooting

### PostgreSQL Connection Error
- Check `DATABASE_URL` in `.env` has correct host, port, credentials
- Ensure PostgreSQL service is running and database exists
- Use `psql` to verify connectivity: `psql -U admin -d ambientacion2 -h localhost`

### Frontend Can't Reach Backend
- Verify backend is running on port 8001
- Check `CORS_ORIGINS` in backend `.env` matches frontend origin
- Browser console shows CORS error if headers mismatch

### Angular Build Fails
- Delete `node_modules` and `dist/` folders
- Run `npm install` and `npm install --with-peer-deps` if peer warnings appear
- Verify Node.js version with `node --version`

### Docker Build Issues
- Ensure Docker daemon is running
- Check `docker-compose.yml` for correct paths relative to workspace root
- Verify sufficient disk space for image layers

## Development Tips

- Backend auto-reloads on file changes (when run with `--reload`)
- Frontend hot-reloads via Angular dev server
- Database is persisted in named volume `postgres_data` (docker-compose)
- Delete `postgres_data` volume to reset database: `docker volume rm ambientacion-2_postgres_data`

## Production Deployment

For production:
1. Set `CORS_ORIGINS` to actual frontend domain
2. Use strong `POSTGRES_PASSWORD`
3. Enable HTTPS in nginx.conf
4. Set FastAPI `debug=False`
5. Use environment-specific `.env` files
6. Configure PostgreSQL backups and replicas

## License

Proprietary - Softtek
