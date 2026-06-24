\set ON_ERROR_STOP on

REVOKE CREATE ON SCHEMA public FROM PUBLIC;

CREATE SCHEMA IF NOT EXISTS metadata;
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS marts;

COMMENT ON SCHEMA metadata IS 'Auditoria técnica, versões e execuções de ingestão.';
COMMENT ON SCHEMA raw IS 'Representação persistida das fontes CSV.';
COMMENT ON SCHEMA staging IS 'Padronização e tipagem dos dados de origem.';
COMMENT ON SCHEMA core IS 'Modelo relacional do domínio futebolístico.';
COMMENT ON SCHEMA marts IS 'Modelos analíticos destinados ao consumo por BI.';
