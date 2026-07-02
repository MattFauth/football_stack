# Football Data Platform ⚽

Um projeto de engenharia de dados *end-to-end* construído para demonstrar boas práticas de extração, carga, transformação (ELT) e visualização, focado na criação de um pequeno Data Warehouse de futebol a partir de dados públicos.

**Arquitetura:** Kaggle → Python → PostgreSQL → dbt → Apache Superset

Toda a stack é orquestrada via **Docker Compose**, processando um volume robusto de dados (mais de 3,1 milhões de escalações e 1,2 milhões de eventos) através de camadas de modelagem bem definidas (Staging, Core e Marts).

---

## ⚙️ Pré-requisitos

Para replicar este projeto localmente, você precisará ter:
1. **Docker Desktop** (com Docker Compose) instalado e rodando na sua máquina.
2. Uma conta no **Kaggle** (para gerar sua credencial de API e baixar o dataset original).

## 🚀 Passo a Passo para Reprodução

### 1. Configuração de Variáveis de Ambiente
Na raiz do projeto, crie o arquivo `.env` copiando a estrutura do exemplo fornecido:
```powershell
# Windows
Copy-Item .env.example .env

# Linux/Mac
cp .env.example .env
```
Abra o arquivo `.env` e configure:
- Senhas dos bancos de dados (`FOOTBALL_DB_PASSWORD`, `SUPERSET_DB_PASSWORD`, etc)
- Sua chave `SUPERSET_SECRET_KEY` (pode ser qualquer hash forte)
- **Credenciais do Kaggle**: `KAGGLE_USERNAME` e `KAGGLE_KEY` para permitir o download automático dos dados cru.

### 2. Construindo as Imagens Docker
Faça o build da infraestrutura:
```bash
docker compose build
```

### 3. Executando o Pipeline Completo de ELT
Temos um container chamado `pipeline` que fará toda a magia de extração, carga e transformação de forma autônoma. 
Execute o comando abaixo e aguarde:
```bash
docker compose run --rm pipeline
```

O que este container fará por debaixo dos panos?
1. Executará `download_data.py` se comunicando com a API do Kaggle e baixando o dataset em CSVs para `data/raw`.
2. Executará `load_raw.py` conectando-se ao PostgreSQL (`football-db`) e criando dinamicamente o Schema `raw` com as tabelas brutas.
3. Instalará as dependências do `dbt`.
4. Rodará o `dbt build`, compilando e materializando as camadas `staging`, `core` e `marts` no Banco de Dados, além de rodar mais de 40 testes de integridade.

### 4. Bônus: Enriquecimento via Web Scraping
Durante o desenvolvimento, notou-se que cerca de 3.095 jogadores possuíam apenas o apelido cadastrado, sem o nome real de batismo. Para sanar isso, construímos um robô extrator assíncrono.
O resultado desse robô já está salvo nativamente no repositório em `dbt/seeds/player_full_names.csv`, então o dbt fará a junção disso automaticamente no `pipeline`.
No entanto, caso você atualize os dados base futuramente e precise buscar o nome de novos jogadores faltantes, basta rodar o extrator:
```bash
# Roda o script e salva no arquivo CSV de Seed
docker compose run --rm shell python scripts/scrape_full_names.py

# Re-executa apenas a camada de dbt para recompilar a dimensão com os novos dados
docker compose run --rm dbt-build
```

### 5. Subindo a Camada de Visualização (Apache Superset)
Com o Data Warehouse pronto e populado, você já pode subir os containers do Superset:
```bash
docker compose up -d superset-db superset-redis superset-web superset-worker
```
*(O Superset fará as migrações no banco interno dele no primeiro boot, o que pode levar cerca de um minuto)*.

**Acessando a plataforma:**
- Abra o seu navegador em: <http://localhost:8088>
- Entre com o login administrador configurado no seu `.env` (Padrão: `admin` / sua-senha)

**Conectando o Data Warehouse:**
Dentro do Superset, crie uma nova conexão de banco de dados PostgreSQL apontando para o host de rede `football-db` com o banco `football` e a senha definida, e comece a construir seus dashboards em cima da *layer* `marts`.

Se você quiser acessar o banco diretamente da sua máquina, use `docker compose exec football-db psql -U football -d football`.

---

## 🏗️ Estrutura Dimensional do DW

Camada de negócios (`marts`) materializada no Postgres após a execução do `pipeline`:
- **Dimensões**: `dim_players`, `dim_teams`, `dim_competitions`
- **Fatos**: `fct_games`, `fct_appearances`, `fct_transfers`, `fct_player_valuations`, `fct_club_games`, `fct_game_events`, `fct_game_lineups`.
