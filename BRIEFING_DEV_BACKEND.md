# Briefing de Contratação — Desenvolvedor Backend / Full Stack
**GGSoft — Plataforma de Jogos Slot**
**Data:** 08/06/2026

---

## Contexto do Projeto

A GGSoft é uma plataforma de jogos slot com arquitetura de microsserviços Docker. O ambiente é composto por 9 containers rodando em rede privada, incluindo serviços de autenticação (CS), histórico de partidas, motor matemático (ZMQ), RGS (Remote Game Server) para múltiplos jogos, lounge de lobby e proxy HTTPS com Let's Encrypt.

O dev contratado irá atuar na evolução, manutenção e novos serviços da plataforma.

---

## Stack Técnica do Ambiente

- **Linguagem principal:** Python (Tornado framework)
- **Infraestrutura:** Docker, Docker Compose, Nginx
- **Banco de dados:** MySQL, Redis
- **Mensageria:** ZeroMQ (ZMQ)
- **Segurança:** Let's Encrypt / Certbot, HTTPS proxy reverso
- **Versionamento:** Git / GitHub (SSH)
- **Jogos:** Haxe (compilado para JS) — não obrigatório, diferencial

---

## Perfis Necessários

### Junior
**Foco:** suporte, tarefas pontuais, manutenção

Requisitos mínimos:
- Python básico (scripts, APIs REST simples)
- Conhecimento de Docker (subir containers, ler logs, entender docker-compose)
- Git (clone, commit, push, branches)
- Leitura de arquivos de configuração (.env, YAML)
- Vontade de aprender arquitetura de microsserviços

Responsabilidades:
- Ajustes de configuração nos serviços existentes
- Suporte em deploys e testes
- Documentação técnica
- Tarefas de QA técnico (rodar scripts de teste, validar endpoints)

---

### Pleno
**Foco:** desenvolvimento de features, integrações, manutenção evolutiva

Requisitos:
- Python intermediário/avançado (Tornado ou FastAPI/Flask)
- Docker e Docker Compose com autonomia
- MySQL e Redis (queries, modelagem básica)
- REST APIs (construção e consumo)
- Nginx (configuração de proxy reverso, virtual hosts)
- Git com fluxo de branches (feature branch, PR, merge)
- Capacidade de ler e entender código legado

Diferenciais:
- Experiência com ZeroMQ ou mensageria assíncrona
- Conhecimento de arquitetura de jogos / iGaming
- HTTPS / Let's Encrypt / Certbot
- Haxe ou qualquer linguagem compilada para JS

Responsabilidades:
- Desenvolvimento de novos endpoints e serviços
- Manutenção e evolução dos serviços existentes (CS, RGS, Lounge, History)
- Integração entre serviços via API e ZMQ
- Configuração e manutenção do proxy HTTPS
- Participação nas sprints do projeto

---

### Sênior
**Foco:** arquitetura, decisões técnicas, liderança técnica do ambiente

Requisitos:
- Python avançado (Tornado obrigatório ou disposição para mergulho rápido)
- Arquitetura de microsserviços com Docker
- MySQL avançado (otimização, migrations, modelagem)
- Redis (cache, pub/sub, sessões)
- ZeroMQ ou mensageria distribuída (RabbitMQ, Kafka — equivalente)
- Nginx avançado (proxy reverso, balanceamento, TLS)
- Segurança de APIs (autenticação, tokens, HTTPS)
- CI/CD básico (GitHub Actions ou equivalente)
- Capacidade de mapear e refatorar arquitetura existente

Diferenciais:
- Experiência com plataformas de iGaming / RGS / operadoras
- Haxe ou engines de jogos
- Conhecimento de compliance / regulação de jogos (diferencial forte)

Responsabilidades:
- Definir e evoluir a arquitetura da plataforma
- Liderar tecnicamente o time de desenvolvimento
- Garantir qualidade, segurança e escalabilidade dos serviços
- Tomar decisões sobre stack, padrões de código e infraestrutura
- Mentorar devs junior e pleno
- Planejar e executar refatorações críticas

---

## Ambiente de Trabalho

- Trabalho remoto
- Metodologia ágil com sprints quinzenais
- Repositórios no GitHub (organização privada GGSoftBR)
- Deploy via Makefile + Docker Compose em servidor Linux
- Comunicação via [definir: Slack / Discord / WhatsApp]

---

## Entregáveis Imediatos (primeiros 30 dias)

- Entender o ambiente completo e subir localmente via `make deploy`
- Contribuir com pelo menos uma feature ou fix em produção
- Participar do projeto de clone de layout Fruits → Tiger (ver FRUITS_TIGER_CLONE_TASKS.md)
- (Sênior) Propor melhorias arquiteturais documentadas

---

## Contato para Encaminhamento

Responsável técnico: Leandro Batista
Projeto: GGSoft
