# TJGO - XLSX -> CSV normalizado (corrigindo "Rendimento Líquido" com vírgula)

library(readxl)
library(readr)
library(stringr)
library(dplyr)

dir.create("projeto/tjgo-xlsx/dados_normalizados", showWarnings = FALSE, recursive = TRUE)

# 1) Ler XLSX (pula 10 linhas do topo, como no estudo)
xlsx_path <- "projeto/tjgo-xlsx/dados_brutos/go0125.xlsx"
raw <- read_excel(xlsx_path, skip = 10)

# Helper para pegar a 1ª coluna existente entre várias possíveis
get_col_any <- function(df, choices) {
  for (nm in choices) if (nm %in% names(df)) return(df[[nm]])
  return(rep(NA_character_, nrow(df)))
}

# 2) Selecionar as 3 colunas (note o nome "Rendimento Líquido" sem (12))
df <- data.frame(
  "Nome" = get_col_any(raw, c("Nome","NOME","nm-pessoa","nm_pessoa")),
  "Cargo" = {
    c1 <- get_col_any(raw, c("Cargo","CARGO","Cargo/Função","Cargo/Funcao","Função","Funcao",
                             "Cargo Função","Cargo Funcao","nm-cargo","nm_cargo"))
    c2 <- get_col_any(raw, c("Cargo Extenso","Cargo/Função Detalhado","Cargo/Função (detalhado)",
                             "nm-cargoext","nm_cargoext"))
    ifelse(is.na(c1) | c1 == "", c2, c1)
  },
  "Rendimento Líquido" = get_col_any(
    raw,
    c("Rendimento Líquido","Rendimento Liquido","vl-rendimento-liquido",
      "Valor Líquido","Valor Liquido","Total Líquido","Total Liquido")
  ),
  check.names = FALSE
)

# 3) Parser/formatter pt-BR robusto
fmt_br2 <- function(x) {
  # converte "21.031,49" -> 21031.49 -> formata "21031,49"
  to_num <- function(v) {
    v <- as.character(v)
    v <- str_squish(v)
    v[v == ""] <- NA
    v <- str_replace_all(v, "\\.", "")   # remove separador de milhar
    v <- str_replace(v, ",", ".")        # vírgula -> ponto (decimal)
    suppressWarnings(as.numeric(v))
  }
  num <- if (is.numeric(x)) x else to_num(x)
  ifelse(is.na(num), "", str_replace(sprintf("%.2f", num), "\\.", ","))
}

# 4) Aplicar normalização (usa a normalizar_cargos() do seu ESTUDO),
#    formatar o líquido e padronizar NOME
df_out <- df |>
  mutate(
    Nome  = str_to_upper(str_squish(Nome)),
    Cargo = normalizar_cargos(Cargo),
    `Rendimento Líquido` = fmt_br2(`Rendimento Líquido`)
  ) |>
  rename(
    NOME = Nome,
    CARGO = Cargo,
    `RENDIMENTO LIQUIDO` = `Rendimento Líquido`
  )

# 5) Salvar CSV com ";" e NA vazio
write_delim(df_out, "projeto/tjgo-xlsx/dados_normalizados/go0125_norm.csv", delim = ";", na = "")

# conferência rápida
head(df_out, 3)
table(df_out$CARGO, useNA = "ifany")
