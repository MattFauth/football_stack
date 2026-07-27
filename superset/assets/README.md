# Assets do Superset

Esta pasta guarda os pacotes exportados pelo Apache Superset para que datasets,
gráficos e dashboards possam ser compartilhados entre diferentes máquinas.

## Fluxo de trabalho

1. Crie ou altere o dashboard no Superset.
2. Exporte o dashboard e suas dependências pela interface do Superset.
3. Salve o pacote exportado nesta pasta.
4. Versione o pacote junto com a mudança que ele representa.
5. Em outra máquina, importe o pacote pela interface do Superset.

O banco interno e o volume Docker do Superset são locais. Eles não devem ser
copiados nem versionados; os pacotes desta pasta são o formato portável do
trabalho analítico.
