# 🧭 Dashboard de Remuneração dos Servidores dos Tribunais de Justiça

Este projeto consolida e analisa dados públicos de remuneração de servidores de três Tribunais de Justiça — **TJGO**, **TJRN** e **TJRO** — entre **setembro/2024 e agosto/2025**, a partir de arquivos CSV normalizados.

O objetivo é permitir **análises comparativas, acompanhamento de variações salariais, identificação de excedentes ao teto constitucional** e **visualização de trajetórias remuneratórias** ao longo do tempo.

---

## ⚙️ Como executar o app

### 🗂️ Estrutura de pastas esperada

```
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
```

> Cada CSV segue o padrão `xxMMYY_norm.csv` (ex: `rn0924_norm.csv`), com colunas como `Nome`, `Cargo` e `Rendimento Líquido`.

---

### 🧩 Requisitos

- **R versão ≥ 4.3**
- Os pacotes abaixo são instalados automaticamente na primeira execução:

```r
shiny, shinydashboard, shinyWidgets, DT, dplyr, tidyr,
readr, stringr, lubridate, janitor, purrr, plotly, scales
```

---

### ▶️ Execução

Abra o R ou RStudio, navegue até a pasta do app e execute:

```r
setwd("projeto/dashboard")
shiny::runApp("app.R")
```

O app abrirá automaticamente em:

```
http://127.0.0.1:xxxx
```

---

## 🧭 Estrutura do Dashboard

### 🔹 1. **Visão Geral**

> Painel inicial com resumo de indicadores e filtros principais.

**Filtros disponíveis:**
- Tribunal (TJGO, TJRN, TJRO)
- Cargo (pode selecionar múltiplos)
- Período (09/2024–08/2025)
- Teto constitucional (padrão R$ 44.000)
- Busca por nome de servidor

**Indicadores (KPIs):**

| Indicador | Significado |
|------------|-------------|
| 🧑‍💼 **Servidores distintos** | Número total de servidores únicos no filtro |
| 💰 **Média** | Média da remuneração líquida |
| ⚖️ **Mediana** | Valor mediano da remuneração líquida |
| 🚨 **Acima do teto** | Quantidade de registros com remuneração > teto |

**Gráficos e Tabelas:**
- 📊 **Histograma** — distribuição das remunerações.
- 📦 **Boxplot por Cargo** — dispersão salarial dos 10 cargos mais frequentes.
- 📋 **Tabela por Função** — top 20 cargos com mais servidores.

---

### 🔹 2. **Maior Remuneração — Últimos 12 meses**

Mostra os **servidores com maior remuneração mensal** considerando os últimos 12 meses do período analisado.

Cada linha representa o **valor máximo recebido por servidor**, exibindo:
- Nome  
- Cargo  
- Tribunal  
- Competência  
- Valor da remuneração  

---

### 🔹 3. **Teto & Impacto**

Analisa o impacto financeiro de remunerações acima do teto constitucional.

**KPIs:**

| Indicador | Significado |
|------------|-------------|
| 📈 **Registros acima do teto** | Número de pagamentos que ultrapassaram o teto |
| 💸 **Impacto total** | Soma total excedente ao teto |
| 🏛️ **Carreira com maior impacto** | Cargo cuja soma de excedentes foi maior |

**Tabela “Impacto por Cargo”:**
- **Impacto Total (R$)** — soma dos valores acima do teto  
- **Servidores Afetados** — número de pessoas que ultrapassaram o teto  
- **Impacto Per Capita (R$)** — média de excesso por servidor  
- 🔽 É possível **baixar o CSV** da tabela

---

### 🔹 4. **Variação Remuneratória**

Avalia as mudanças salariais ao longo do tempo.

**Tabelas:**
1. **Ranking por Servidor (Δ máx − mín)**  
   → Servidores com **maior variação salarial** no período.
2. **Ranking por Cargo (Δ de média e mediana)**  
   → Cargos com **maiores oscilações na média e mediana salarial**.

---

### 🔹 5. **Trajetórias**

Acompanha a evolução das remunerações ao longo dos meses.

**Gráficos:**
- 📈 **Trajetória por Servidor** — curva individual de remuneração ao longo do tempo.  
  > Útil para visualizar gratificações, progressões e variações mensais.
- 📉 **Trajetória por Cargo (média & mediana)** — evolução da média e mediana salarial do cargo selecionado.

---

### 🔹 6. **Análises Avançadas**

Explora tendências, correlações e comparações entre tribunais.

**Gráficos incluídos:**

1. 🧾 **Folha Total Mensal (R$)**  
   Soma total das remunerações mês a mês e número de servidores ativos.  
   > Mostra a evolução do gasto total com pessoal.

2. ⚖️ **Média por TJ ao longo do tempo**  
   Comparativo entre os três tribunais, evidenciando diferenças estruturais.

3. 🚨 **Excedentes ao teto por mês**  
   Gráfico combinado:  
   - **Barras** → quantidade de servidores acima do teto  
   - **Linha** → impacto financeiro total dos excedentes  

---

### 🔹 7. **Dados (Auditoria)**

Tabela completa dos registros filtrados (nome, cargo, tribunal, competência e valor).  
Permite auditoria direta e exportação manual dos dados.

---

## 📘 Notas Técnicas

- Todos os valores foram tratados e convertidos para **formato numérico (R$)**.  
- As datas de competência são inferidas automaticamente a partir dos nomes dos arquivos (`xxMMYY_norm.csv`).  
- Casos de remuneração implausível (> 200.000) são automaticamente reescalonados.  
- O teto constitucional padrão é **R$ 44.000**, mas pode ser ajustado dinamicamente.  

---

## 🧠 Extensões Futuras (sugestões)

- 📊 Treemap da distribuição de cargos por tribunal  
- 🔍 Detecção de outliers salariais (>3 desvios padrão)  
- 🔗 Correlação entre número de servidores e média salarial  
- 📈 Projeção da folha futura com regressão linear ou Prophet  

---

## 👨‍💻 Autor

**Felipe Duarte**  
Mestrado Profissional em Computação Aplicada – IPT  
Tema: *Análise de Dados e Inteligência Artificial Aplicada à Administração Pública*
