⚙️ Como executar o app
1. Estrutura de pastas esperada
projeto/
├── dashboard/
│   └── app.R
├── tjgo-xlsx/
│   └── dados_normalizados/
│       ├── go0924_norm.csv
│       ├── go1024_norm.csv
│       └── ...
├── tjrn-csv/
│   └── dados_normalizados/
│       ├── rn0924_norm.csv
│       ├── rn1024_norm.csv
│       └── ...
├── tjro-xml/
│   └── dados_normalizados/
│       ├── ro0924_norm.csv
│       ├── ro1024_norm.csv
│       └── ...


Cada CSV segue o padrão xxMMYY_norm.csv (ex: rn0924_norm.csv), com colunas como Nome, Cargo e Rendimento Líquido.

2. Requisitos

R versão ≥ 4.3

Pacotes (instalados automaticamente na primeira execução):

shiny, shinydashboard, shinyWidgets, DT, dplyr, tidyr,
readr, stringr, lubridate, janitor, purrr, plotly, scales

3. Execução

Abra o R ou RStudio, navegue até a pasta do app e execute:

setwd("projeto/dashboard")
shiny::runApp("app.R")


O app abrirá automaticamente em:

http://127.0.0.1:xxxx

🧩 Estrutura do Dashboard
🔹 1. Aba “Visão Geral”

Panorama geral do período e filtros principais.

Filtros disponíveis:

Tribunal (TJGO, TJRN, TJRO)

Cargo (pode selecionar múltiplos)

Período (09/2024–08/2025)

Teto constitucional (padrão R$ 44.000)

Busca por nome de servidor

Indicadores (KPIs):

Indicador	Significado
Servidores distintos	Número total de servidores únicos no filtro
Média	Média da remuneração líquida
Mediana	Valor mediano da remuneração líquida
Acima do teto	Quantidade de registros com remuneração > teto

Gráficos e Tabelas:

📊 Histograma — distribuição das remunerações.

📦 Boxplot por Cargo — dispersão salarial dos 10 cargos mais frequentes.

📋 Tabela por Função — top 20 cargos com mais servidores.

🔹 2. Aba “Maior Remuneração — Últimos 12 meses”

Mostra os servidores com maior remuneração mensal considerando os últimos 12 meses do período analisado.

Cada linha representa o valor máximo recebido por servidor no intervalo.

Exibe nome, cargo, tribunal, competência e valor da remuneração.

🔹 3. Aba “Teto & Impacto”

Analisa o impacto financeiro de remunerações acima do teto constitucional.

KPIs:

Indicador	Significado
Registros acima do teto	Número de pagamentos que ultrapassaram o teto
Impacto total	Soma total excedente ao teto
Carreira com maior impacto	Cargo cuja soma de excedentes foi maior

Tabela “Impacto por Cargo”:

Impacto Total (R$) — soma dos valores acima do teto;

Servidores Afetados — número de pessoas que ultrapassaram o teto;

Impacto Per Capita (R$) — média de excesso por servidor;

É possível baixar o CSV da tabela.

🔹 4. Aba “Variação Remuneratória”

Avalia mudanças de remuneração ao longo do tempo.

Gráficos/Tabelas:

Ranking por Servidor (Δ máx − mín)
Mostra os servidores com maior variação salarial no período.

Ranking por Cargo (Δ de média e mediana)
Mostra quais cargos tiveram maiores oscilações na média e mediana salarial.

🔹 5. Aba “Trajetórias”

Acompanha a evolução das remunerações ao longo dos meses.

Gráficos:

Trajetória por Servidor — exibe a curva individual de um servidor buscado por nome.

Útil para analisar progressões, gratificações ou pagamentos variáveis.

Trajetória por Cargo (média & mediana) — evolução mensal da média e mediana salarial do cargo.

🔹 6. Aba “Análises Avançadas”

Explora tendências e correlações gerais entre tribunais e períodos.

Gráficos incluídos:

🧾 Folha Total Mensal (R$)
Soma total das remunerações mês a mês e número de servidores ativos.

Mostra a evolução do gasto total com pessoal.

⚖️ Média por TJ ao longo do tempo
Comparativo entre os três tribunais, evidenciando diferenças estruturais.

🚨 Excedentes ao teto por mês
Gráfico duplo com:

Barras → quantidade de servidores acima do teto por mês;

Linha → impacto financeiro total dos excedentes.

🔹 7. Aba “Dados (Auditoria)”

Exibe a tabela completa dos registros filtrados (nome, cargo, tribunal, competência e valor).
Permite auditoria direta e exportação manual de dados.

📘 Notas Técnicas

Todos os valores foram tratados e convertidos para formato numérico padrão (R$).

Datas de competência foram inferidas automaticamente dos nomes dos arquivos (xxMMYY_norm.csv).

Casos de remuneração implausível (> 200.000) são automaticamente reescalonados.

O teto constitucional padrão é R$ 44.000, mas pode ser alterado dinamicamente.

🧠 Extensões futuras sugeridas

Treemap da distribuição de cargos por tribunal;

Detecção de outliers salariais (>3 desvios padrão);

Correlação entre número de servidores e média salarial;

Previsão da folha futura com regressão linear ou Prophet.

👨‍💻 Autor

Felipe Duarte
Mestrado Profissional em Computação Aplicada – IPT
Tema: Análise de Dados e Inteligência Artificial Aplicada à Administração Pública
