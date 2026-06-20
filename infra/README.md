<div align="center">

# 📓 DevBook

**A full-stack developer notebook — capture tagged notes, showcase projects, and ship the whole thing from local Docker Compose to AWS EKS.**

![Node](https://img.shields.io/badge/Node.js-20-339933?logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-5-000000?logo=express&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![Vite](https://img.shields.io/badge/Vite-7-646CFF?logo=vite&logoColor=white)
![Tailwind](https://img.shields.io/badge/Tailwind-4-06B6D4?logo=tailwindcss&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-6-2D3748?logo=prisma&logoColor=white)
![Postgres](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-1.6+-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20ECR-FF9900?logo=amazonaws&logoColor=white)

</div>

---

## Overview

DevBook is a small but complete full-stack application that demonstrates a production-style stack: a React single-page UI talking to an Express + Prisma API backed by PostgreSQL, all containerized and reproducible with Docker Compose — and an Infrastructure-as-Code layer that stands up the AWS foundation (EKS, RDS, ECR, VPC) with Terraform.

After signing up, a user can:

- ✍️ **Write notes** with a title, body, and a set of tags.
- 📦 **Track projects** with a description, a list of links, and `public` / `private` visibility.
- 📊 **See live stats** on their dashboard — note count, project count, public projects, and unique tags.

Authentication is JWT-based using an **httpOnly cookie** (no token in `localStorage`), with passwords hashed via bcrypt.

---

## Architecture

```mermaid
flowchart LR
    U([User]) --> FE["Frontend<br/>React 19 + Vite + Tailwind<br/>(served by nginx)"]
    FE -- "/api/* proxied" --> BE["Backend API<br/>Express 5 + Prisma"]
    BE -- "SQL" --> DB[("PostgreSQL 16")]

    subgraph Local["Local — docker-compose"]
        FE
        BE
        DB
    end

    subgraph AWS["AWS — provisioned by Terraform"]
        EKS["EKS cluster"]
        RDS[("RDS PostgreSQL")]
        ECR["ECR image registry"]
        ALB["ALB + Load Balancer Controller"]
    end
```

**Request flow:** the React app calls relative `/api/*` paths. In local dev, Vite (or nginx in the container) proxies those to the backend on port `3000`. The backend authenticates the request from the `accessToken` cookie, then reads/writes Postgres through Prisma.

---

## Tech Stack

| Layer | Technology |
| --- | --- |
| **Frontend** | React 19, Vite 7, Tailwind CSS 4 |
| **Backend** | Node.js 20, Express 5 (ESM), Prisma ORM 6 |
| **Database** | PostgreSQL 16 |
| **Auth** | JSON Web Tokens (httpOnly cookie) + bcrypt |
| **Containers** | Docker, Docker Compose, nginx (frontend serving + API proxy) |
| **Infrastructure** | Terraform — AWS VPC, EKS, RDS, ECR, ALB IRSA; S3 + DynamoDB remote state |

---

## Project Structure

```
devbook/
├── backend/                  # Express + Prisma API
│   ├── src/
│   │   ├── index.js          # App entry: middleware + route mounting
│   │   ├── auth.js           # /api/auth — signup & login
│   │   ├── notes.js          # /api/notes — list & create
│   │   ├── projects.js       # /api/projects — list & create
│   │   └── middleware.js     # requireAuth — verifies the JWT cookie
│   ├── prisma/
│   │   ├── schema.prisma     # User, Note, Project models + Visibility enum
│   │   └── migrations/       # SQL migrations (init + cascade delete)
│   └── Dockerfile            # Multi-stage build
│
├── frontend/                 # React + Vite SPA
│   ├── src/
│   │   ├── pages/            # Landing, Auth, Dashboard
│   │   ├── components/       # Panel, NoteForm, ProjectForm
│   │   └── lib/cryptoId.js   # Tiny demo id helper
│   ├── default.conf          # nginx config (serves SPA + proxies /api)
│   └── Dockerfile            # Build → nginx serve
│
├── infra/                    # Terraform IaC
│   ├── bootstrap/            # S3 state bucket + DynamoDB lock table
│   └── environments/dev/     # VPC, EKS, RDS, ECR, ALB IRSA, security groups
│
└── docker-compose.yml        # db → migrate → backend → frontend
```

---

## Getting Started (Local, with Docker Compose)

The fastest path — one command brings up Postgres, runs migrations, and starts the API and UI.

**Prerequisites:** Docker and Docker Compose.

```bash
git clone https://github.com/erysimum/devbook.git
cd devbook
docker compose up --build
```

Then open:

| Service | URL |
| --- | --- |
| Frontend | http://localhost:5173 |
| Backend API | http://localhost:3000/api/health |

The compose stack starts services in order: **db** (with a healthcheck) → **migrate** (`prisma migrate deploy`) → **backend** → **frontend**.

> ⚠️ The secrets in `docker-compose.yml` (`devpass`, `devbook-dev-secret`) are for **local development only**. Never reuse them in a deployed environment.

---

## Running Without Docker (manual dev)

**Backend**

```bash
cd backend
npm install

# Create backend/.env
cat > .env <<'EOF'
DATABASE_URL="postgresql://devbook:devpass@localhost:5432/devbook?schema=public"
ACCESS_TOKEN_SECRET="change-me"
PORT=3000
EOF

npx prisma migrate dev      # apply migrations to a running Postgres
npm run dev                 # nodemon on http://localhost:3000
```

**Frontend**

```bash
cd frontend
npm install
npm run dev                 # Vite on http://localhost:5173, proxies /api → :3000
```

---

## Environment Variables

| Variable | Used by | Description |
| --- | --- | --- |
| `DATABASE_URL` | backend | PostgreSQL connection string |
| `ACCESS_TOKEN_SECRET` | backend | Secret used to sign & verify JWT access tokens |
| `PORT` | backend | API port (defaults to `3000`) |

---

## API Reference

Base path: `/api`. Authenticated routes require the `accessToken` cookie set at login/signup.

### Auth

| Method | Endpoint | Body | Description |
| --- | --- | --- | --- |
| `POST` | `/api/auth/signup` | `{ email, password }` | Create account, set auth cookie, returns `{ id, email }` |
| `POST` | `/api/auth/login` | `{ email, password }` | Log in, set auth cookie, returns `{ id, email }` |

### Notes 🔒

| Method | Endpoint | Body | Description |
| --- | --- | --- | --- |
| `GET` | `/api/notes` | — | List the current user's notes (newest first) |
| `POST` | `/api/notes` | `{ title, content?, tags? }` | Create a note (`title` required) |

### Projects 🔒

| Method | Endpoint | Body | Description |
| --- | --- | --- | --- |
| `GET` | `/api/projects` | — | List the current user's projects (newest first) |
| `POST` | `/api/projects` | `{ name, description?, links?, visibility? }` | Create a project (`name` required; `visibility` ∈ `private`/`public`) |

### Health

| Method | Endpoint | Description |
| --- | --- | --- |
| `GET` | `/api/health` | Liveness check — `{ ok: true }` |

🔒 = requires authentication.

---

## Data Model

```
User ──┬──< Note
       └──< Project
```

| Model | Fields |
| --- | --- |
| **User** | `id`, `email` (unique), `password` (hashed), `createdAt`, `refreshToken?` |
| **Note** | `id`, `title`, `content`, `tags[]`, `userId`, `createdAt` |
| **Project** | `id`, `name`, `description`, `links[]`, `visibility` (`private`/`public`), `userId`, `createdAt` |

Deleting a user cascades to their notes and projects.

---

## Infrastructure (AWS, Terraform)

The `infra/` directory provisions the cloud foundation in two steps.

**1. Bootstrap remote state** (`infra/bootstrap`) — creates an encrypted, versioned S3 bucket for Terraform state and a DynamoDB table for state locking.

```bash
cd infra/bootstrap
terraform init
terraform apply
```

**2. Provision the dev environment** (`infra/environments/dev`) — stands up the application platform:

- **VPC** with public / private / database subnets across 2 AZs
- **EKS** cluster with a managed on-demand node group (IRSA enabled)
- **RDS PostgreSQL 16** in private database subnets with a custom parameter group
- **ECR** repositories with a lifecycle policy to retain recent images
- **AWS Load Balancer Controller** IRSA role + service account
- Security groups wiring ALB → backend and EKS nodes → RDS

```bash
cd infra/environments/dev
terraform init -backend-config=backend.hcl
terraform apply -var-file=dev.tfvars
```

> The S3 backend config (`backend.hcl`) and `*.tfvars` are gitignored — supply your own with the bucket/lock-table names from the bootstrap outputs and your environment values (region, CIDRs, DB credentials, ECR repo list).

---

## Roadmap

- [ ] Update & delete endpoints for notes and projects
- [ ] Refresh-token rotation (currently scaffolded but disabled)
- [ ] Automated tests (backend + frontend)
- [ ] Kubernetes manifests / Helm charts to deploy onto the provisioned EKS cluster
- [ ] CI/CD pipeline (build → push to ECR → deploy)

---

