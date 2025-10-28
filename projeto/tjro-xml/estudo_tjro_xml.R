# TJRO - XML

# Carregamento das bibliotecas:
library(xml2)
library(stringr)

# Lendo todo XML
xml_path <- "projeto/tjro-xml/dados_brutos/ro0125.xml"
doc <- read_xml(xml_path)
doc

# nós de registro mais comuns; ajuste se necessário
nodes <- xml_find_all(doc, "//object | //registro | //item")
if (length(nodes) == 0) stop("Nenhum registro encontrado no XML.")

# constrói um data.frame com todas as colunas do 1º registro
first_children <- xml_children(nodes[[1]])
cols <- xml_name(first_children)

make_row <- function(node, cols) {
  vapply(cols, function(tag) {
    x <- xml_find_first(node, tag)
    if (length(x) == 0) NA_character_ else xml_text(x)
  }, FUN.VALUE = character(1))
}

mat <- do.call(rbind, lapply(nodes, make_row, cols = cols))
todos_dados_xml <- as.data.frame(mat, stringsAsFactors = FALSE)
names(todos_dados_xml) <- cols

head(todos_dados_xml)

# Lendo apenas colunas selecionadas (mapeando nomes do XML para os nomes do estudo)
get_col <- function(df, primary, fallback = NULL) {
  if (primary %in% names(df)) return(df[[primary]])
  if (!is.null(fallback) && fallback %in% names(df)) return(df[[fallback]])
  return(rep(NA_character_, nrow(df)))
}

colunas_xml <- data.frame(
  "Nome" = get_col(todos_dados_xml, "nm-pessoa"),
  "Cargo" = {
    c1 <- get_col(todos_dados_xml, "nm-cargo")
    c2 <- get_col(todos_dados_xml, "nm-cargoext")
    ifelse(is.na(c1) | c1 == "", c2, c1)
  },
  "Rendimento Líquido (12)" = get_col(todos_dados_xml, "vl-rendimento-liquido"),
  check.names = FALSE
)

head(colunas_xml, 3)

# Lendo todos valores dos cargos
col_cargo <- colunas_xml$Cargo
col_cargo_unico <- unique(col_cargo)
print(col_cargo_unico)

# Normalizando colunas cargos nos 11 grupos unificados (RN + RO)
# (somente stringr; ordem de prioridade evita conflitos)
normalizar_cargos <- function(cargos) {
  r <- cargos |>
    str_squish() |>
    str_to_lower()

  out <- rep("OUTROS", length(r))
  is_out <- function() out == "OUTROS"

  # 1) ASSESSORIA/COMISSIONADO (captura '... DE DESEMBARGADOR', chefias e gabinetes)
  out[ is_out() & str_detect(r, "assessor|assistente de gabinete|oficial de gabinete|\\bgabinete\\b|\\bchefe\\b|coordenador|diretor|secretar|requisitad|cargo requisitado") ] <-
    "ASSESSORIA/COMISSIONADO"

  # 2) OFICIAL DE JUSTIÇA
  out[ is_out() & str_detect(r, "oficial de justi[cç]a") ] <- "OFICIAL DE JUSTIÇA"

  # 3) ESCRIVANIA (ESCRIVÃO/ESC.)
  out[ is_out() & (str_detect(r, "^esc\\.") | str_detect(r, "\\bescriv")) ] <- "ESCRIVÃO"

  # 4) SAÚDE/PSICOSSOCIAL (psicologia/serviço social; inclusive 'técnico ... assistente social')
  out[ is_out() & str_detect(r, "psicolog|servi[cç]o social|assistente social") ] <- "SAÚDE/PSICOSSOCIAL"

  # 5) SEGURANÇA
  out[ is_out() & str_detect(r, "seguran") ] <- "SEGURANÇA"

  # 6) ESTAGIÁRIO
  out[ is_out() & str_detect(r, "estagi") ] <- "ESTAGIÁRIO"

  # 7) MAGISTRADO (juiz/desembargador)
  out[ is_out() & str_detect(r, "\\b(desembargador|juiz)\\b") ] <- "MAGISTRADO"

  # 8) TÉCNICO
  out[ is_out() & str_detect(r, "\\bt[eé]cnic[oa]\\b|t[eé]cnico judici[aá]rio") ] <- "TÉCNICO"

  # 9) ANALISTA (e profissões RO: administrador, matemático, contador; também TI/sistemas)
  out[ is_out() & (str_detect(r, "\\banalista\\b") |
                   str_detect(r, "administrador") |
                   str_detect(r, "matem[aá]tic|matematico") |
                   str_detect(r, "contador") |
                   str_detect(r, "sistema|\\bti\\b|inform[aá]t")) ] <- "ANALISTA"

  # 10) AUXILIAR/OPERACIONAL (apoio/gerais; inclui 'serviços gerais')
  out[ is_out() & str_detect(r, "auxiliar|ajudante|deposit[aá]r|servi[cç]os gerais") ] <- "AUXILIAR/OPERACIONAL"

  toupper(out)
}

cargos_norm <- normalizar_cargos(colunas_xml$Cargo)
cargos_norm_unico <- unique(cargos_norm)
print(cargos_norm_unico)
