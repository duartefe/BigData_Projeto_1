# TJGO - XLSX (ESTUDO) — somente console

# Carregamento das bibliotecas:
library(readxl)
library(stringr)

# 1) Lendo todo XLSX (pula as 10 primeiras linhas de topo)
xlsx_path <- "projeto/tjgo-xlsx/dados_brutos/go0125.xlsx"
todos_dados_xlsx <- read_excel(xlsx_path, skip = 10)
head(todos_dados_xlsx)

# 2) Lendo apenas colunas selecionadas (mapeando nomes do XLSX para os nomes do estudo)
get_col_any <- function(df, choices) {
  for (nm in choices) if (nm %in% names(df)) return(df[[nm]])
  return(rep(NA_character_, nrow(df)))
}

colunas_xlsx <- data.frame(
  "Nome" = get_col_any(todos_dados_xlsx, c("Nome","NOME","nm-pessoa","nm_pessoa")),
  "Cargo" = {
    c1 <- get_col_any(todos_dados_xlsx, c(
      "Cargo","CARGO","Cargo/Função","Cargo/Funcao","Função","Funcao",
      "Cargo Função","Cargo Funcao","nm-cargo","nm_cargo"
    ))
    c2 <- get_col_any(todos_dados_xlsx, c(
      "Cargo Extenso","Cargo/Função Detalhado","Cargo/Função (detalhado)",
      "nm-cargoext","nm_cargoext"
    ))
    ifelse(is.na(c1) | c1 == "", c2, c1)
  },
  "Rendimento Líquido (12)" = get_col_any(
    todos_dados_xlsx,
    c("Rendimento Líquido (12)","Rendimento Líquido","Rendimento Liquido",
      "Remuneração Líquida","Remuneracao Liquida","Valor Líquido","Valor Liquido",
      "Total Líquido","Total Liquido","Líquido","Liquido","vl-rendimento-liquido")
  ),
  check.names = FALSE
)

head(colunas_xlsx, 3)

# 3) Lendo todos os valores dos cargos (para revisar)
col_cargo <- colunas_xlsx$Cargo
col_cargo_unico <- unique(col_cargo)
print(col_cargo_unico)

# 4) Normalizando colunas cargos nos 11 grupos (ordem de prioridade evita conflitos)
normalizar_cargos <- function(cargos) {
  r <- cargos |>
    str_squish() |>
    str_to_lower()

  out <- rep("OUTROS", length(r))
  is_out <- function() out == "OUTROS"

  # 1) ASSESSORIA/COMISSIONADO
  out[ is_out() & str_detect(r, "assessor|assistente de gabinete|oficial de gabinete|\\bgabinete\\b|\\bchefe\\b|coordenador|diretor|secretar|requisitad|cargo requisitado|ouvidor") ] <-
    "ASSESSORIA/COMISSIONADO"

  # 2) OFICIAL DE JUSTIÇA
  out[ is_out() & str_detect(r, "oficial de justi[cç]a") ] <-
    "OFICIAL DE JUSTIÇA"

  # 3) ESCRIVÃO (escrivão/escrevente/escriturário/“esc.”/registro civil/distribuidor/partidor/porteiro judiciário/depositário/oficializado)
  out[ is_out() & str_detect(
        r,
        "^esc\\.|\\bescriv|\\bescritur|oficial de registro civil|\\bdistribuidor(?!.*gest)|\\bpartidor|porteiro judiciario|depositario|oficializad"
      ) ] <- "ESCRIVÃO"

  # 4) SAÚDE/PSICOSSOCIAL
  out[ is_out() & str_detect(
        r,
        "psicolog|servi[cç]o social|assistente social|m[eé]dic|enfermag|sa[uú]de|vigil[aâ]ncia sanit[aá]ria|endemi|agente de servi[cç]o social"
      ) ] <- "SAÚDE/PSICOSSOCIAL"

  # 5) SEGURANÇA
  out[ is_out() & str_detect(
        r,
        "seguran|vigia|vigilant|guarda( civil)?|penitenci[aá]rio|prisional|pol[ií]cia|tr[aâ]nsit|transporte coletivo|comiss[aá]rio de vigil[aâ]ncia de menores"
      ) ] <- "SEGURANÇA"

  # 6) ESTAGIÁRIO
  out[ is_out() & str_detect(r, "estagi") ] <- "ESTAGIÁRIO"

  # 7) MAGISTRADO
  out[ is_out() & str_detect(r, "\\b(desembargador|juiz)\\b|entrancia|turma recursal|substituto( em segundo grau)?") ] <-
    "MAGISTRADO"

  # 8) TÉCNICO
  out[ is_out() & str_detect(r, "\\bt[eé]cnic[oa]\\b|t[eé]cnico judici[aá]rio") ] <-
    "TÉCNICO"

  # 9) ANALISTA (inclui admin/bibliotec/contador/auditor/gestor/TI/arquitet*/matematic*)
  out[ is_out() & str_detect(
        r,
        "\\banalista\\b|administrador|bibliotec|contador(?!.*distribuidor)|auditor(?!.*sa[uú]de)|\\bgestor\\b|sistema|\\bti\\b|inform[aá]t|arquit(et|e)|matematic"
      ) ] <- "ANALISTA"

  # 10) AUXILIAR/OPERACIONAL
  out[ is_out() & str_detect(
        r,
        "auxiliar|ajudante|deposit[aá]r|servi[cç]os? gerais|merendeir|cozinheir|zelador|operador\\b|motorist|telefonist|recepcionist|atendente|recreador|executor( de)? servi[cç]os|higiene|alimenta[cç][aã]o|\\bcmei\\b|porteiro"
      ) ] <- "AUXILIAR/OPERACIONAL"

  toupper(out)
}

# 5) Aplicando normalização e exibindo no console (como nos seus exemplos)
cargos_norm <- normalizar_cargos(colunas_xlsx$Cargo)
cargos_norm_unico <- unique(cargos_norm)
print(cargos_norm_unico)

# Frequência por categoria (ajuda a validar rapidamente)
print(table(cargos_norm, useNA = "ifany"))
