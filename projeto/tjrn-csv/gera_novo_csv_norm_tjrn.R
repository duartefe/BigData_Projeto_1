library(readr)
library(stringr)
library(dplyr)

# Apenas para garantir que a pasta para salvar os normalizados exista
dir.create("projeto/tjrn-csv/dados_normalizados", showWarnings = FALSE, recursive = TRUE)

# Passo 1 - ler só as 3 colunas selecionadas a partir do estudo
df <- read_csv2(
  "projeto/tjrn-csv/dados_brutos/rn0125.csv",
  col_select = c("Nome", "Cargo", "Rendimento Líquido (12)"),
  show_col_types = FALSE
)

# Passo 2 - formatar número em pt-BR (2 casas e vírgula)
fmt_br2 <- function(x) {
  ifelse(is.na(x), "",
         str_replace(sprintf("%.2f", as.numeric(x)), "\\.", ","))
}

# Passo 3 - aplicar normalização de cargos, formatar líquido e MAIÚSCULO em Nome
df_out <- df |>
  mutate(
    Nome  = str_to_upper(str_squish(Nome)),
    Cargo = normalizar_cargos(Cargo),      
    `Rendimento Líquido (12)` = fmt_br2(`Rendimento Líquido (12)`)
  ) |>
  # renomeia cabeçalho usando apenas texto e MAIÚSCULO (sem parênteses/números)
  rename(
    NOME = Nome,
    CARGO = Cargo,
    `RENDIMENTO LIQUIDO` = `Rendimento Líquido (12)`
  )

# Passo 4 - salvar CSV usando ";" como separador, NA vazio
write_delim(df_out, "projeto/tjrn-csv/dados_normalizados/rn0125_norm.csv", delim = ";", na = "")

# conferência
head(df_out, 3)
