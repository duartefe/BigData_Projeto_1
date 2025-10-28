library(readr)
library(stringr)
library(dplyr)

# Apenas para garantir que a pasta para salvar os normalizados exista
dir.create("projeto/tjrn-csv/dados_normalizados", showWarnings = FALSE, recursive = TRUE)

# Lista todos os arquivos rnXXXX.csv na pasta de entrada (evita pegar os _norm.csv)
arquivos <- list.files("projeto/tjrn-csv/dados_brutos", pattern = "^rn\\d{4}\\.csv$", full.names = TRUE)

# Passo 1 - (dentro do loop) ler só as 3 colunas selecionadas a partir do estudo
# Passo 2 - formatar número em pt-BR (2 casas e vírgula)
fmt_br2 <- function(x) {
  ifelse(is.na(x), "",
         str_replace(sprintf("%.2f", as.numeric(x)), "\\.", ","))
}

# Processa cada arquivo
for (f in arquivos) {
  message("Processando: ", basename(f))

  df <- read_csv2(
    f,
    col_select = c("Nome", "Cargo", "Rendimento Líquido (12)"),
    show_col_types = FALSE
  )

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
  out_path <- file.path("projeto/tjrn-csv/dados_normalizados",
                        sub("\\.csv$", "_norm.csv", basename(f)))
  write_delim(df_out, out_path, delim = ";", na = "")

  # conferência (mostra a 1ª linha do arquivo atual)
  print(head(df_out, 1))
}

message("Concluído: ", length(arquivos), " arquivo(s) processado(s).")
