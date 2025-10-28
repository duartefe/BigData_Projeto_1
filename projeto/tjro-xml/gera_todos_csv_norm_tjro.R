library(xml2)
library(stringr)
library(dplyr)
library(readr)

# Apenas para garantir que a pasta para salvar os normalizados exista
dir.create("projeto/tjro-xml/dados_normalizados", showWarnings = FALSE, recursive = TRUE)

# Lista todos os arquivos roXXXX.xml na pasta de entrada
arquivos <- list.files("projeto/tjro-xml/dados_brutos", pattern = "^ro\\d{4}\\.xml$", full.names = TRUE)

# Passo 1 - (dentro do loop) ler só as 3 colunas selecionadas a partir do estudo

# Passo 2 - formatar número em pt-BR (2 casas e vírgula)
fmt_br2 <- function(x) {
  # aceita "1234.56", "1.234,56" ou numérico; NA -> ""
  if (is.numeric(x)) {
    return(sub("\\.", ",", sprintf("%.2f", x)))
  }
  xx <- as.character(x)
  xx <- str_squish(xx)
  xx <- str_replace_all(xx, "\\.", "")  # remove separador de milhares
  xx <- str_replace(xx, ",", ".")       # vírgula -> decimal
  y  <- suppressWarnings(as.numeric(xx))
  ifelse(is.na(y), "", sub("\\.", ",", sprintf("%.2f", y)))
}

# Funções auxiliares do estudo
get_col <- function(df, primary, fallback = NULL) {
  if (primary %in% names(df)) return(df[[primary]])
  if (!is.null(fallback) && fallback %in% names(df)) return(df[[fallback]])
  return(rep(NA_character_, nrow(df)))
}

normalizar_cargos <- function(cargos) {
  r <- cargos |> str_squish() |> str_to_lower()
  out <- rep("OUTROS", length(r))
  is_out <- function() out == "OUTROS"

  # 1) ASSESSORIA/COMISSIONADO
  out[ is_out() & str_detect(r, "assessor|assistente de gabinete|oficial de gabinete|\\bgabinete\\b|\\bchefe\\b|coordenador|diretor|secretar|requisitad|cargo requisitado") ] <- "ASSESSORIA/COMISSIONADO"
  # 2) OFICIAL DE JUSTIÇA
  out[ is_out() & str_detect(r, "oficial de justi[cç]a") ] <- "OFICIAL DE JUSTIÇA"
  # 3) ESCRIVÃO (ESC./escriv…)
  out[ is_out() & (str_detect(r, "^esc\\.") | str_detect(r, "\\bescriv")) ] <- "ESCRIVÃO"
  # 4) SAÚDE/PSICOSSOCIAL
  out[ is_out() & str_detect(r, "psicolog|servi[cç]o social|assistente social") ] <- "SAÚDE/PSICOSSOCIAL"
  # 5) SEGURANÇA
  out[ is_out() & str_detect(r, "seguran") ] <- "SEGURANÇA"
  # 6) ESTAGIÁRIO
  out[ is_out() & str_detect(r, "estagi") ] <- "ESTAGIÁRIO"
  # 7) MAGISTRADO
  out[ is_out() & str_detect(r, "\\b(desembargador|juiz)\\b") ] <- "MAGISTRADO"
  # 8) TÉCNICO
  out[ is_out() & str_detect(r, "\\bt[eé]cnic[oa]\\b|t[eé]cnico judici[aá]rio") ] <- "TÉCNICO"
  # 9) ANALISTA (inclui administrador, matemático, contador, TI/sistemas)
  out[ is_out() & (str_detect(r, "\\banalista\\b") |
                   str_detect(r, "administrador") |
                   str_detect(r, "matem[aá]tic|matematico") |
                   str_detect(r, "contador") |
                   str_detect(r, "sistema|\\bti\\b|inform[aá]t")) ] <- "ANALISTA"
  # 10) AUXILIAR/OPERACIONAL
  out[ is_out() & str_detect(r, "auxiliar|ajudante|deposit[aá]r|servi[cç]os gerais") ] <- "AUXILIAR/OPERACIONAL"

  toupper(out)
}

# Processa cada arquivo
for (f in arquivos) {
  message("Processando: ", basename(f))

  # Lê o XML bruto
  doc <- read_xml(f)
  nodes <- xml_find_all(doc, "//object | //registro | //item")
  if (length(nodes) == 0) {
    message("Sem registros em: ", basename(f))
    next
  }

  # Inferir colunas do 1º registro
  first_children <- xml_children(nodes[[1]])
  cols <- xml_name(first_children)

  make_row <- function(node, cols) {
    vapply(cols, function(tag) {
      x <- xml_find_first(node, tag)
      if (length(x) == 0) NA_character_ else xml_text(x)
    }, FUN.VALUE = character(1))
  }

  mat <- do.call(rbind, lapply(nodes, make_row, cols = cols))
  dados_xml <- as.data.frame(mat, stringsAsFactors = FALSE)
  names(dados_xml) <- cols

  # Seleciona as 3 colunas do estudo
  df <- data.frame(
    "Nome" = get_col(dados_xml, "nm-pessoa"),
    "Cargo" = {
      c1 <- get_col(dados_xml, "nm-cargo")
      c2 <- get_col(dados_xml, "nm-cargoext")
      ifelse(is.na(c1) | c1 == "", c2, c1)
    },
    "Rendimento Líquido (12)" = get_col(dados_xml, "vl-rendimento-liquido"),
    check.names = FALSE
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
  out_path <- file.path("projeto/tjro-xml/dados_normalizados",
                        sub("\\.xml$", "_norm.csv", basename(f)))
  write_delim(df_out, out_path, delim = ";", na = "")

  # conferência (mostra a 1ª linha do arquivo atual)
  print(head(df_out, 1))
}

message("Concluído: ", length(arquivos), " arquivo(s) processado(s).")
