# 🧭 Dashboard de Remuneração dos Servidores dos Tribunais de Justiça

Este projeto consolida e analisa dados públicos de remuneração de servidores de três Tribunais de Justiça — **TJGO**, **TJRN** e **TJRO** — entre **setembro/2024 e agosto/2025**.  
Os dados passam por um **processo de ETL (extração, tratamento e normalização)** em R e alimentam o **dashboard Shiny** que permite análises consolidadas e comparativas.

---

## ⚙️ Estrutura do projeto

```
projeto/
├── dashboard/
│   └── app.R
├── tjgo-xlsx/
│   ├── dados_brutos/
│   └── dados_normalizados/
├── tjrn-csv/
│   ├── dados_brutos/
│   └── dados_normalizados/
├── tjro-xml/
│   ├── dados_brutos/
│   └── dados_normalizados/
└── README.md
```

> Cada TJ possui três scripts `.R` responsáveis por estudar, limpar e gerar os arquivos CSV normalizados usados no dashboard.

---

## 📘 Etapas de Processamento e Normalização

Cada Tribunal de Justiça (TJGO, TJRN, TJRO) possui **três scripts principais** que realizam o pré-processamento dos dados:

### 1️⃣ Estudo inicial dos dados
**Objetivo:** analisar a estrutura original e criar a função de normalização dos cargos/funções.

Este script:
- Lê o arquivo bruto (`dados_brutos/`);
- Analisa colunas como `Nome`, `Cargo` e `Rendimento Líquido`;
- Lista e inspeciona valores únicos de cargos;
- Define a função `normalizar_cargos()`, que agrupa diferentes descrições de cargos em categorias padronizadas (ex.: *MAGISTRADO*, *ANALISTA*, *TÉCNICO*, *OFICIAL DE JUSTIÇA*, *ASSESSORIA/COMISSIONADO*, etc.).

### 2️⃣ Geração de um CSV normalizado (teste)
**Objetivo:** aplicar a função de normalização e conferir o resultado em um único mês.

Este script:
- Lê um arquivo bruto específico (ex.: `rn0125.csv`);
- Aplica limpeza nos nomes (maiúsculas, sem espaços);
- Normaliza o campo de cargo;
- Formata o campo de remuneração em padrão brasileiro (vírgula como decimal);
- Renomeia as colunas para o padrão do dashboard (`NOME`, `CARGO`, `RENDIMENTO LIQUIDO`);
- Gera um arquivo normalizado de conferência em `dados_normalizados/` (ex.: `rn0125_norm.csv`).

### 3️⃣ Geração de todos os CSVs normalizados (processamento em lote)
**Objetivo:** aplicar o mesmo processo a todos os meses disponíveis.

Este script:
- Lista todos os arquivos da pasta `dados_brutos/` (ex.: `rn0924.csv`, `rn1024.csv`, etc.);
- Para cada arquivo:
  - Lê apenas as colunas necessárias;
  - Aplica a função `normalizar_cargos()`;
  - Formata o campo de remuneração;
  - Renomeia colunas para o padrão do dashboard;
  - Gera o arquivo `_norm.csv` correspondente na pasta `dados_normalizados/`;
- Exibe no console os arquivos processados e confirma a conclusão.

**Resultado final:**  
Cada TJ passa a ter uma série de arquivos normalizados (`xxMMYY_norm.csv`), padronizados e prontos para serem lidos pelo dashboard Shiny.

---

## 🧭 Estrutura e Execução do Dashboard

### ▶️ Como rodar o app

1. Abra o R ou Positron.
2. Defina o diretório de trabalho:
   ```r
   setwd("projeto/dashboard")
   ```
3. Execute o app:
   ```r
   shiny::runApp("app.R")
   ```
4. O app abrirá automaticamente em `http://127.0.0.1:xxxx`.

---

## 🧩 Abas do Dashboard

| Aba | Conteúdo |
|-----|-----------|
| **Visão Geral** | KPIs (servidores distintos, média, mediana, acima do teto), histograma, boxplot e tabela por função |
| **Maior Remuneração** | Servidores com maior remuneração mensal no último ano |
| **Teto & Impacto** | Excedentes ao teto constitucional, impacto total e por cargo |
| **Variação Remuneratória** | Servidores e cargos com maior variação salarial |
| **Trajetórias** | Evolução das remunerações por servidor ou cargo |
| **Análises Avançadas** | Tendências, médias por TJ, folha mensal e excedentes ao teto |
| **Dados (Auditoria)** | Tabela detalhada com todos os registros filtrados |

---

## 🔧 Notas Técnicas

- O campo **`RENDIMENTO LIQUIDO`** é convertido e tratado automaticamente no app Shiny.  
- As **datas de competência** são extraídas do nome do arquivo (`xxMMYY_norm.csv`).  
- O **teto constitucional** é fixo em R$ 44.000 (ajustável no painel).  
- Casos extremos de remuneração (> R$ 200.000) são filtrados automaticamente no carregamento.

---

## 🧠 Extensões Futuras

- Detecção automática de outliers salariais (>3 desvios padrão)  
- Projeção da folha salarial futura  
- Clusterização de cargos por faixa de remuneração  
- Dashboard comparativo entre TJs por carreira e impacto orçamentário

---

## 👨‍💻 Autor

**Felipe Duarte**  
Mestrado Profissional em Computação Aplicada – IPT  
Tema: *Análise de Dados e Inteligência Artificial Aplicada à Administração Pública*
