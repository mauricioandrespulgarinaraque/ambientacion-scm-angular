from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, String, DateTime, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime, timezone
import uuid
import os
from pathlib import Path
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# PostgreSQL connection
DATABASE_URL = os.environ.get('DATABASE_URL', 'postgresql://admin:password@localhost:5432/ambientacion2')
engine = create_engine(DATABASE_URL, echo=False)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models (SQLAlchemy ORM)
class TemplateORM(Base):
    __tablename__ = "templates"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    provider = Column(String, nullable=False)
    resource_type = Column(String, nullable=False)
    content = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class TicketORM(Base):
    __tablename__ = "tickets"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    resources_json = Column(String, nullable=False)  # stored as JSON string
    consolidated_content = Column(String, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

# Pydantic Schemas
class TemplateCreate(BaseModel):
    name: str
    provider: str
    resource_type: str
    content: str

class TemplateUpdate(BaseModel):
    name: Optional[str] = None
    provider: Optional[str] = None
    resource_type: Optional[str] = None
    content: Optional[str] = None

class Template(BaseModel):
    id: str
    name: str
    provider: str
    resource_type: str
    content: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class Resource(BaseModel):
    id: str
    name: str
    provider: str

class TicketCreate(BaseModel):
    resource_ids: List[str]

class Ticket(BaseModel):
    id: str
    consolidated_content: str
    created_at: datetime

    class Config:
        from_attributes = True

# Predefined resources
PREDEFINED_RESOURCES = [
    {"id": "gcp-vm", "name": "Compute Engine (VM)", "provider": "GCP"},
    {"id": "gcp-gke", "name": "Google Kubernetes Engine (GKE)", "provider": "GCP"},
    {"id": "gcp-gar", "name": "Artifact Registry (AR)", "provider": "GCP"},
    {"id": "gcp-storage", "name": "Cloud Storage", "provider": "GCP"},
    {"id": "gcp-sql", "name": "Cloud SQL", "provider": "GCP"},
    {"id": "azure-vm", "name": "Virtual Machines", "provider": "Azure"},
    {"id": "azure-aks", "name": "Azure Kubernetes Service (AKS)", "provider": "Azure"},
    {"id": "azure-acr", "name": "Container Registry (ACR)", "provider": "Azure"},
    {"id": "azure-blob", "name": "Blob Storage", "provider": "Azure"},
    {"id": "azure-sql", "name": "Azure SQL Database", "provider": "Azure"},
]

# Create tables on startup
Base.metadata.create_all(bind=engine)

# FastAPI app
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_resource_type_from_id(resource_id: str) -> str:
    parts = resource_id.split('-')
    if len(parts) >= 2:
        return parts[1].upper()
    return resource_id.upper()

# Routes
@app.get("/api/")
async def root():
    return {"message": "Cloud Resource Template Manager API"}

# Templates
@app.post("/api/templates", response_model=Template)
async def create_template(input: TemplateCreate, db: Session = Depends(get_db)):
    resource_type = input.resource_type.upper()
    template = TemplateORM(
        name=input.name,
        provider=input.provider,
        resource_type=resource_type,
        content=input.content
    )
    db.add(template)
    db.commit()
    db.refresh(template)
    return template

@app.get("/api/templates", response_model=List[Template])
async def get_templates(db: Session = Depends(get_db)):
    templates = db.query(TemplateORM).all()
    return templates

@app.get("/api/templates/{template_id}", response_model=Template)
async def get_template(template_id: str, db: Session = Depends(get_db)):
    template = db.query(TemplateORM).filter(TemplateORM.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template

@app.put("/api/templates/{template_id}", response_model=Template)
async def update_template(template_id: str, input: TemplateUpdate, db: Session = Depends(get_db)):
    template = db.query(TemplateORM).filter(TemplateORM.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    
    if input.name is not None:
        template.name = input.name
    if input.provider is not None:
        template.provider = input.provider
    if input.resource_type is not None:
        template.resource_type = input.resource_type.upper()
    if input.content is not None:
        template.content = input.content
    
    db.commit()
    db.refresh(template)
    return template

@app.delete("/api/templates/{template_id}")
async def delete_template(template_id: str, db: Session = Depends(get_db)):
    template = db.query(TemplateORM).filter(TemplateORM.id == template_id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    db.delete(template)
    db.commit()
    return {"message": "Template deleted successfully"}

# Resources
@app.get("/api/resources", response_model=List[Resource])
async def get_resources():
    return PREDEFINED_RESOURCES

# Tickets
@app.post("/api/tickets/generate")
async def generate_ticket(input: TicketCreate, db: Session = Depends(get_db)):
    if not input.resource_ids:
        raise HTTPException(status_code=400, detail="No resources selected")
    
    selected_resources = [r for r in PREDEFINED_RESOURCES if r["id"] in input.resource_ids]
    if not selected_resources:
        raise HTTPException(status_code=400, detail="Invalid resource IDs")
    
    consolidated_content = ""
    for resource in selected_resources:
        resource_type = get_resource_type_from_id(resource["id"])
        templates = db.query(TemplateORM).filter(
            TemplateORM.provider == resource["provider"],
            TemplateORM.resource_type == resource_type
        ).all()
        
        if templates:
            consolidated_content += f"\n\n=== {resource['provider']} - {resource['name']} ===\n\n"
            for tpl in templates:
                if tpl.name:
                    consolidated_content += f"-- {tpl.name} --\n"
                consolidated_content += tpl.content + "\n\n"
    
    if not consolidated_content:
        consolidated_content = "No se encontraron plantillas para los recursos seleccionados."
    
    ticket = TicketORM(
        resources_json=str(selected_resources),
        consolidated_content=consolidated_content.strip()
    )
    db.add(ticket)
    db.commit()
    db.refresh(ticket)
    
    return {"id": ticket.id, "consolidated_content": ticket.consolidated_content, "created_at": ticket.created_at}

@app.get("/api/tickets")
async def get_tickets(db: Session = Depends(get_db)):
    tickets = db.query(TicketORM).order_by(TicketORM.created_at.desc()).all()
    return [{"id": t.id, "consolidated_content": t.consolidated_content, "created_at": t.created_at} for t in tickets]

@app.get("/api/tickets/{ticket_id}")
async def get_ticket(ticket_id: str, db: Session = Depends(get_db)):
    ticket = db.query(TicketORM).filter(TicketORM.id == ticket_id).first()
    if not ticket:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return {"id": ticket.id, "consolidated_content": ticket.consolidated_content, "created_at": ticket.created_at}
