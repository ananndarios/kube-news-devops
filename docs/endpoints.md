# Documentação de Endpoints — Kube-News

---

### GET /

**Descrição:** Renderiza a página inicial com todas as notícias cadastradas

**Parâmetros:** Nenhum

**Retorno:** Página HTML com grid de notícias (`index.ejs`)

**Códigos HTTP:** 200 (sucesso), 500 (erro ao buscar posts no banco)

---

### GET /post

**Descrição:** Renderiza o formulário para criação de uma nova notícia

**Parâmetros:** Nenhum

**Retorno:** Página HTML com formulário vazio (`edit-news.ejs`)

**Códigos HTTP:** 200 (sucesso)

---

### POST /post

**Descrição:** Recebe e persiste uma nova notícia no banco de dados

**Parâmetros (body form-urlencoded):**
- `title` — título da notícia (máx. 30 caracteres, obrigatório)
- `summary` — resumo (máx. 50 caracteres, obrigatório)
- `content` — conteúdo completo (máx. 2000 caracteres, obrigatório)
- `publishDate` — data de publicação (obrigatório)

**Retorno:** Redireciona para `/` em caso de sucesso; re-renderiza o formulário com erros de validação em caso de falha

**Códigos HTTP:** 302 (redirect após sucesso), 200 (formulário com erros), 500 (erro interno)

---

### GET /post/:id

**Descrição:** Renderiza a página de detalhe de uma notícia específica

**Parâmetros (path):**
- `id` — identificador numérico da notícia

**Retorno:** Página HTML com conteúdo completo da notícia (`view-news.ejs`)

**Códigos HTTP:** 200 (sucesso), 500 (erro ao buscar post no banco)

---

### POST /api/post

**Descrição:** Insere múltiplas notícias em massa via API (usado para popular o banco com dados de teste)

**Parâmetros (body JSON):** Array de objetos contendo:
- `title` — título da notícia
- `summary` — resumo
- `content` — conteúdo completo
- `publishDate` — data de publicação

**Retorno:** JSON com array das notícias inseridas

**Códigos HTTP:** 200 (sucesso), 500 (erro interno)

---

### GET /health

**Descrição:** Liveness probe — indica se a aplicação está viva e funcionando (usado pelo Kubernetes)

**Parâmetros:** Nenhum

**Retorno:** JSON `{ state: "up", machine: "<hostname>" }`

**Códigos HTTP:** 200 (aplicação saudável), 500 (aplicação em estado de falha via `/unhealth`)

---

### GET /ready

**Descrição:** Readiness probe — indica se a aplicação está pronta para receber tráfego (usado pelo Kubernetes)

**Parâmetros:** Nenhum

**Retorno:** Sem corpo

**Códigos HTTP:** 200 (pronta para receber tráfego), 500 (em período de indisponibilidade simulada)

---

### GET /metrics

**Descrição:** Expõe métricas no formato Prometheus para scraping pelo servidor de monitoramento

**Parâmetros:** Nenhum

**Retorno:** Texto no formato Prometheus com métricas HTTP (latência, contagem de requisições por rota/método/status) e métricas padrão do Node.js

**Códigos HTTP:** 200 (sucesso)

---

### PUT /unhealth

**Descrição:** Simula falha permanente na aplicação — após chamada, todos os endpoints passam a retornar 500 (chaos engineering)

**Parâmetros:** Nenhum

**Retorno:** Sem corpo

**Códigos HTTP:** 200 (falha ativada com sucesso)

---

### PUT /unreadyfor/:seconds

**Descrição:** Simula indisponibilidade temporária na readiness probe — útil para testar comportamento do load balancer do Kubernetes

**Parâmetros (path):**
- `seconds` — duração em segundos da indisponibilidade simulada

**Retorno:** Sem corpo

**Códigos HTTP:** 200 (simulação iniciada com sucesso)
