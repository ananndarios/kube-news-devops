# Relatório do Cluster Kubernetes
**Data:** 16/05/2026  
**Cluster:** do-nyc1-k8s-devopspro (DigitalOcean — NYC1)

---

## 1. Inventário de Hardware

### Nodes

| Node | Status | CPU Total | CPU Alocável | Memória Total | Memória Alocável |
|------|--------|-----------|--------------|---------------|-----------------|
| pool-devopspro-33rk4n | Ready | 2 vCPUs | 1900m | ~2 GB | ~1.46 GB |
| pool-devopspro-33rkh9 | Ready | 2 vCPUs | 1900m | ~2 GB | ~1.46 GB |

### Utilização de Recursos por Node

| Node | CPU Utilizado | Memória Utilizada |
|------|--------------|-------------------|
| pool-devopspro-33rk4n | 602m (31%) | 625Mi (42%) |
| pool-devopspro-33rkh9 | 602m (31%) | 625Mi (42%) |

### Informações do Sistema

- **OS:** Debian GNU/Linux 13 (trixie)
- **Kernel:** 6.12.86+deb13-amd64
- **Kubernetes:** v1.35.1
- **Container Runtime:** containerd 1.7.29
- **CNI:** Cilium (com Hubble para observabilidade)

---

## 2. Pods em Execução

### Namespace: devops-aula01

| Pod | Status | Restarts | Node | IP |
|-----|--------|----------|------|-----|
| kube-news-5bb44f7cd4-q9mmb | Running 1/1 | 3 | pool-devopspro-33rk4n | 10.108.0.65 |
| postgres-79468bdd7d-2mdgg | Running 1/1 | 0 | pool-devopspro-33rk4n | 10.108.0.83 |

### Namespace: default (recursos órfãos — a remover)

| Pod | Status | Restarts | Node |
|-----|--------|----------|------|
| kube-news-5bb44f7cd4-v7d8r | Running 1/1 | 0 | pool-devopspro-33rkh9 |
| postgres-79468bdd7d-6nmsx | Running 1/1 | 0 | pool-devopspro-33rkh9 |

### Namespace: kube-system (infraestrutura)

| Pod | Status | Função |
|-----|--------|--------|
| cilium-* (x2) | Running | CNI / rede entre pods |
| coredns-* (x2) | Running | DNS interno do cluster |
| cpc-bridge-proxy-* (x2) | Running | Proxy eBPF |
| csi-do-node-* (x2) | Running | Driver de volumes (DigitalOcean) |
| do-node-agent-* (x2) | Running | Agente de monitoramento DO |
| hubble-relay / hubble-ui | Running | Observabilidade de rede |
| konnectivity-agent-* (x2) | Running | Conectividade com control plane |
| doks-telemetry-* (x2) | Running | Telemetria DOKS |

---

## 3. Aplicações em Execução

### kube-news

| Atributo | Valor |
|----------|-------|
| Namespace | devops-aula01 |
| Imagem | 030100501/kube-news:latest |
| Réplicas | 1/1 |
| Porta | 8080 (container) |
| Acesso externo | http://167.172.2.40 (porta 80) |
| Tipo de serviço | LoadBalancer |
| Volumes | Nenhum |

### postgres

| Atributo | Valor |
|----------|-------|
| Namespace | devops-aula01 |
| Imagem | postgres:16-alpine |
| Réplicas | 1/1 |
| Porta | 5432 |
| Acesso | ClusterIP (interno) |
| Volume | PVC 1Gi (do-block-storage) — Bound |

### Load Balancers Provisionados

| Serviço | IP Externo | Porta | Namespace |
|---------|-----------|-------|-----------|
| kube-news | 167.172.2.40 | 80 | devops-aula01 |
| kube-news | 138.197.228.38 | 80 | default (órfão) |

---

## 4. Status de Saúde do Cluster e das Aplicações

### Cluster

| Componente | Status |
|-----------|--------|
| Nodes | ✅ Todos Ready |
| Control Plane | ✅ Acessível |
| CoreDNS | ✅ Running (2 réplicas) |
| Cilium CNI | ✅ Running |
| CSI (volumes) | ✅ Running |
| PVC devops-aula01 | ✅ Bound |
| PVC default | ⚠️ Terminating (resquício de migração) |

### Aplicações

| Aplicação | Namespace | Saúde | Observação |
|-----------|-----------|-------|-----------|
| kube-news | devops-aula01 | ⚠️ Running | 3 restarts (race condition na inicialização com o Postgres) |
| postgres | devops-aula01 | ✅ Running | Estável, 0 restarts |
| kube-news | default | ⚠️ Órfão | Rodando sem necessidade — deve ser removido |
| postgres | default | ⚠️ Órfão | Rodando sem necessidade — deve ser removido |

---

## 5. Sugestões de Melhorias

### 🔴 Alta Prioridade

**1. Remover recursos do namespace `default`**  
Existem dois pods, dois serviços e um Load Balancer ativos no namespace `default` — resquícios da migração para o `devops-aula01`. Isso gera custo desnecessário (Load Balancer na DigitalOcean é cobrado por hora).
```bash
kubectl delete all --all -n default
```

**2. Adicionar `initContainer` no kube-news para aguardar o Postgres**  
Os 3 restarts do pod `kube-news` ocorrem porque a aplicação inicia antes do Postgres estar pronto. Um `initContainer` resolve o problema de forma elegante, sem depender do comportamento de retry do Kubernetes.

**3. Definir `resources` (requests e limits) nos containers**  
Nenhum container possui `resources` definidos. Sem isso, o Kubernetes não consegue fazer scheduling eficiente e um pod pode consumir toda a memória do node, derrubando outros.

### 🟡 Média Prioridade

**4. Trocar tag `latest` por versão fixa na imagem**  
O uso de `latest` dificulta rastreabilidade e pode causar deploy involuntário de versões quebradas. O recomendado é usar tags semânticas (`v1.0.0`) ou o SHA do commit.

**5. Configurar `livenessProbe` e `readinessProbe` no kube-news**  
A aplicação já possui os endpoints `/health` e `/ready`, mas eles não estão configurados nos manifestos Kubernetes. Isso impede que o cluster detecte e reinicie automaticamente pods com problemas.

**6. Criar os ambientes `dev`, `hom` e `prod` no cluster**  
Os overlays Kustomize foram criados, mas os namespaces e recursos ainda não foram aplicados no cluster. Aplicar os três ambientes permite validação progressiva antes de ir para produção.

**7. Usar StatefulSet para o PostgreSQL**  
O PostgreSQL está rodando como `Deployment`, o que não garante identidade de rede estável nem ordem de inicialização. O `StatefulSet` é o recurso correto para bancos de dados com estado.

### 🟢 Baixa Prioridade

**8. Configurar Horizontal Pod Autoscaler (HPA) no prod**  
Com o overlay de produção configurado para 3 réplicas fixas, o HPA permitiria escalar automaticamente com base na carga real, otimizando custo.

**9. Ativar o Metrics Server**  
O comando `kubectl top nodes/pods` não está disponível pois o Metrics Server não está instalado. Ele é necessário para monitoramento de recursos e para o HPA funcionar.
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**10. Configurar política de `ImagePullPolicy: Always`**  
Com a tag `latest`, o Kubernetes pode usar uma versão em cache ao invés de baixar a mais recente. Definir `imagePullPolicy: Always` garante consistência nos deploys.
