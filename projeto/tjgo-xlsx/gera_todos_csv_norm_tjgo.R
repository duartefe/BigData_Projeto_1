# TJGO - XLSX -> CSV (todos os meses, com normalização embutida)

library(readxl)
library(readr)
library(stringr)
library(dplyr)

# Garante a pasta de saída
dir.create("projeto/tjgo-xlsx/dados_normalizados", showWarnings = FALSE, recursive = TRUE)

# Lista todos os arquivos goXXXX.xlsx na pasta de entrada
arquivos <- list.files("projeto/tjgo-xlsx/dados_brutos", pattern = "^go\\d{4}\\.xlsx$", full.names = TRUE)

# Helper: pega a 1ª coluna existente dentre várias opções
get_col_any <- function(df, choices) {
  for (nm in choices) if (nm %in% names(df)) return(df[[nm]])
  return(rep(NA_character_, nrow(df)))
}

# ---- Normalização dos cargos (mesmas regras do ESTUDO TJGO) ----
normalizar_cargos <- function(cargos) {
  r <- cargos |>
    str_squish() |>
    str_to_lower()

  out <- rep("OUTROS", length(r))
  is_out <- function() out == "OUTROS"

  # 1) ASSESSORIA/COMISSIONADO
  out[ is_out() & str_detect(r, "assessor|assistente de gabinete|oficial de gabinete|\\bgabinete\\b|\\bchefe\\b|coordenador|diretor|secretar|requisitad|cargo requisitado|ouvidor") ] <- "ASSESSORIA/COMISSIONADO"

  # 2) OFICIAL DE JUSTIÇA
  out[ is_out() & str_detect(r, "oficial de justi[cç]a") ] <- "OFICIAL DE JUSTIÇA"

  # 3) ESCRIVÃO (escrivão/escrevente/escriturário/esc./registro civil/distribuidor/partidor/porteiro judiciário/depositário/oficializado)
  out[ is_out() & str_detect(r, "^esc\\.|\\bescriv|\\bescritur|oficial de registro civil|\\bdistribuidor(?!.*gest)|\\bpartidor|porteiro judiciario|depositario|oficializad") ] <- "ESCRIVÃO"

  # 4) SAÚDE/PSICOSSOCIAL
  out[ is_out() & str_detect(r, "psicolog|servi[cç]o social|assistente social|m[eé]dic|enfermag|sa[uú]de|vigil[aâ]ncia sanit[aá]ria|endemi|agente de servi[cç]o social") ] <- "SAÚDE/PSICOSSOCIAL"

  # 5) SEGURANÇA
  out[ is_out() & str_detect(r, "seguran|vigia|vigilant|guarda( civil)?|penitenci[aá]rio|prisional|pol[ií]cia|tr[aâ]nsit|transporte coletivo|comiss[aá]rio de vigil[aâ]ncia de menores") ] <- "SEGURANÇA"

  # 6) ESTAGIÁRIO
  out[ is_out() & str_detect(r, "estagi") ] <- "ESTAGIÁRIO"

  # 7) MAGISTRADO
  out[ is_out() & str_detect(r, "\\b(desembargador|juiz)\\b|entrancia|turma recursal|substituto( em segundo grau)?") ] <- "MAGISTRADO"

  # 8) TÉCNICO
  out[ is_out() & str_detect(r, "\\bt[eé]cnic[oa]\\b|t[eé]cnico judici[aá]rio") ] <- "TÉCNICO"

  # 9) ANALISTA (admin/bibliotec/contador/auditor/gestor/TI/arquitet*/matematic*)
  out[ is_out() & str_detect(r, "\\banalista\\b|administrador|bibliotec|contador(?!.*distribuidor)|auditor(?!.*sa[uú]de)|\\bgestor\\b|sistema|\\bti\\b|inform[aá]t|arquit(et|e)|matematic") ] <- "ANALISTA"

  # 10) AUXILIAR/OPERACIONAL
  out[ is_out() & str_detect(r, "auxiliar|ajudante|deposit[aá]r|servi[cç]os? gerais|merendeir|cozinheir|zelador|operador\\b|motorist|telefonist|recepcionist|atendente|recreador|executor( de)? servi[cç]os|higiene|alimenta[cç][aã]o|\\bcmei\\b|porteiro") ] <- "AUXILIAR/OPERACIONAL"

  toupper(out)
}

# Passo 2 - formatar número em pt-BR (aceita "21.031,49")
fmt_br2 <- function(x) {
  to_num <- function(v) {
    v <- as.character(v)
    v <- str_squish(v)
    v[v == ""] <- NA
    v <- str_replace_all(v, "\\.", "")  # milhar
    v <- str_replace(v, ",", ".")       # decimal
    suppressWarnings(as.numeric(v))
  }
  num <- if (is.numeric(x)) x else to_num(x)
  ifelse(is.na(num), "", str_replace(sprintf("%.2f", num), "\\.", ","))
}

# Processa cada arquivo
for (f in arquivos) {
  message("Processando: ", basename(f))

  # Passo 1 - ler só as 3 colunas selecionadas a partir do estudo (XLSX usa read_excel + skip)
  raw <- read_excel(f, skip = 10)

  df <- data.frame(
    "Nome" = get_col_any(raw, c("Nome","NOME","nm-pessoa","nm_pessoa")),
    "Cargo" = {
      c1 <- get_col_any(raw, c(
        "Cargo","CARGO","Cargo/Função","Cargo/Funcao","Função","Funcao",
        "Cargo Função","Cargo Funcao","nm-cargo","nm_cargo"
      ))
      c2 <- get_col_any(raw, c(
        "Cargo Extenso","Cargo/Função Detalhado","Cargo/Função (detalhado)",
        "nm-cargoext","nm_cargoext"
      ))
      ifelse(is.na(c1) | c1 == "", c2, c1)
    },
    # No TJGO o nome costuma ser "Rendimento Líquido" (sem (12))
    "Rendimento Líquido" = get_col_any(
      raw,
      c("Rendimento Líquido","Rendimento Liquido","vl-rendimento-liquido",
        "Valor Líquido","Valor Liquido","Total Líquido","Total Liquido")
    ),
    check.names = FALSE
  )

  # Passo 3 - aplicar normalização de cargos, formatar líquido e MAIÚSCULO em Nome
  df_out <- df |>
    mutate(
      Nome  = str_to_upper(str_squish(Nome)),
      Cargo = normalizar_cargos(Cargo),
      `Rendimento Líquido` = fmt_br2(`Rendimento Líquido`)
    ) |>
    # renomeia cabeçalho usando apenas texto e MAIÚSCULO (sem parênteses/números)
    rename(
      NOME = Nome,
      CARGO = Cargo,
      `RENDIMENTO LIQUIDO` = `Rendimento Líquido`
    )

  # Passo 4 - salvar CSV usando ";" como separador, NA vazio
  out_path <- file.path("projeto/tjgo-xlsx/dados_normalizados",
                        sub("\\.xlsx$", "_norm.csv", basename(f)))
  write_delim(df_out, out_path, delim = ";", na = "")

  # conferência (mostra a 1ª linha do arquivo atual)
  print(head(df_out, 1))
}

message("Concluído: ", length(arquivos), " arquivo(s) processado(s).")
