# Diagrama de Arquitetura - ListaPro Multi-Cloud

## 🏗️ Arquitetura Multi-Cloud

```mermaid
graph TB
    subgraph "GitHub"
        GH[GitHub Repository]
        GA[GitHub Actions]
    end
    
    subgraph "Produção - Google Cloud Platform"
        subgraph "GKE Cluster"
            subgraph "Namespace: listapro"
                GFE[Frontend Pods<br/>Nginx + Next.js]
                GBE[Backend Pods<br/>Go API]
                GPG[PostgreSQL Pod]
                GPV[Persistent Volume]
            end
            
            subgraph "Monitoring"
                GPR[Prometheus]
                GGR[Grafana]
                GAL[AlertManager]
            end
        end
        
        GLB[Google Load Balancer]
        GAR[Artifact Registry]
    end
    
    subgraph "Homologação - Digital Ocean"
        subgraph "DOKS Cluster"
            subgraph "Namespace: listapro"
                DFE[Frontend Pods<br/>Nginx + Next.js]
                DBE[Backend Pods<br/>Go API]
                DPG[PostgreSQL Pod]
                DPV[Persistent Volume]
            end
            
            subgraph "Monitoring"
                DPR[Prometheus]
                DGR[Grafana]
                DAL[AlertManager]
            end
        end
        
        DLB[Digital Ocean Load Balancer]
        DCR[Container Registry]
    end
    
    subgraph "External Users"
        UP[Prod Users]
        US[Stage Users]
    end
    
    subgraph "Infrastructure as Code"
        TGC[Terraform - GCP]
        TDO[Terraform - Digital Ocean]
    end
    
    %% Connections
    GH --> GA
    GA --> TGC
    GA --> TDO
    GA --> GAR
    GA --> DCR
    
    TGC --> GLB
    TDO --> DLB
    
    GLB --> GFE
    DLB --> DFE
    
    GFE --> GBE
    DFE --> DBE
    
    GBE --> GPG
    DBE --> DPG
    
    GPG --> GPV
    DPG --> DPV
    
    GPR --> GFE
    GPR --> GBE
    GPR --> GPG
    
    DPR --> DFE
    DPR --> DBE
    DPR --> DPG
    
    UP --> GLB
    US --> DLB
    
    %% Styling
    classDef cloud fill:#e1f5fe
    classDef k8s fill:#f3e5f5
    classDef app fill:#e8f5e8
    classDef db fill:#fff3e0
    classDef monitor fill:#fce4ec
    classDef cicd fill:#f1f8e9
    
    class GLB,DLB,GAR,DCR cloud
    class GFE,DFE,GBE,DBE k8s
    class GPG,DPG,GPV,DPV db
    class GPR,DPR,GGR,DGR,GAL,DAL monitor
    class GH,GA,TGC,TDO cicd
```

## 🌊 Fluxo de Deploy

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GA as GitHub Actions
    participant TF as Terraform
    participant GCP as Google Cloud
    participant DO as Digital Ocean
    participant K8s as Kubernetes
    
    Dev->>GH: git push main (prod)
    GH->>GA: Trigger Pipeline
    
    GA->>GA: Run Tests
    GA->>GA: Build Docker Image
    
    GA->>TF: terraform apply
    TF->>GCP: Provision GKE Cluster
    TF->>GCP: Create Load Balancer
    TF->>GCP: Setup Artifact Registry
    
    GA->>GCP: Push Image to Registry
    GA->>K8s: Deploy Manifests
    K8s->>K8s: Create Pods
    K8s->>K8s: Setup Services
    K8s->>K8s: Mount Persistent Volumes
    
    GA->>K8s: Deploy Monitoring
    K8s->>K8s: Install Prometheus
    K8s->>K8s: Install Grafana
    
    Note over Dev,K8s: Similar flow for Digital Ocean (branch: release)
```

## 🔄 Arquitetura de Rede Interna

```mermaid
graph LR
    subgraph "Kubernetes Cluster"
        subgraph "Frontend Service"
            FP1[Frontend Pod 1]
            FP2[Frontend Pod 2]
        end
        
        subgraph "Backend Service"
            BP1[Backend Pod 1]
            BP2[Backend Pod 2]
        end
        
        subgraph "Database"
            DB[PostgreSQL Pod]
            PV[Persistent Volume]
        end
        
        LB[Load Balancer] --> FP1
        LB --> FP2
        
        FP1 --> BP1
        FP1 --> BP2
        FP2 --> BP1
        FP2 --> BP2
        
        BP1 --> DB
        BP2 --> DB
        DB --> PV
    end
    
    Internet[Internet] --> LB
```

## 📊 Fluxo de Dados

```mermaid
graph TD
    U[User Browser] -->|HTTP Request| LB[Load Balancer]
    LB -->|Route to Pod| FE[Frontend Pod - Nginx]
    
    FE -->|Static Files| SF[Static Assets]
    FE -->|API Calls /api/*| PR[Nginx Proxy]
    
    PR -->|Proxy Pass| BE[Backend Service]
    BE -->|Query| DB[PostgreSQL]
    
    DB -->|Response| BE
    BE -->|JSON| PR
    PR -->|JSON| FE
    FE -->|HTML/JS/CSS| LB
    LB -->|Response| U
    
    subgraph "Monitoring Flow"
        PR -->|Metrics| PM[Prometheus]
        BE -->|Metrics| PM
        DB -->|Metrics| PM
        PM -->|Query| GR[Grafana]
    end
```

## 🛡️ Segurança e Isolamento

```mermaid
graph TB
    subgraph "Network Security"
        NP[Network Policies]
        SG[Security Groups]
        FW[Firewall Rules]
    end
    
    subgraph "Application Security"
        TLS[TLS Termination]
        SEC[Kubernetes Secrets]
        RBAC[RBAC Policies]
    end
    
    subgraph "Data Security"
        ENC[Encryption at Rest]
        BKP[Automated Backups]
        PV[Persistent Volumes]
    end
    
    Internet -->|HTTPS| TLS
    TLS --> NP
    NP --> SG
    SG --> FW
    
    SEC --> ENC
    ENC --> PV
    PV --> BKP
```

---

## 📋 Legenda

| Componente | Descrição | Tecnologia |
|------------|-----------|------------|
| **Frontend** | Interface do usuário | Next.js 15 + TypeScript |
| **Proxy** | Roteamento e CORS | Nginx |
| **Backend** | API REST | Go + Gin Framework |
| **Database** | Armazenamento de dados | PostgreSQL 17 |
| **Monitoring** | Observabilidade | Prometheus + Grafana |
| **CI/CD** | Automação | GitHub Actions |
| **IaC** | Infraestrutura | Terraform |
| **Orquestração** | Container management | Kubernetes |
