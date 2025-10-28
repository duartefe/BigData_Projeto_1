# TJRN - CSV

# Carregamento das bibliotecas:
library(readr)
library(stringr)

# Lendo todo csv
todos_dados_csv <- read_csv2("projeto/tjrn-csv/dados_brutos/rn0125.csv")
head(todos_dados_csv)

#Lendo apenas colunas selecionadas
colunas_csv <- read_csv2("projeto/tjrn-csv/dados_brutos/rn0125.csv", col_select = c("Nome", "Cargo", "Rendimento Líquido (12)"))
head(colunas_csv, 3)

#Lendo todos valores dos cargos
todos_dados_csv <- read_csv2("projeto/tjrn-csv/dados_brutos/rn0125.csv")
col_cargo <- todos_dados_csv$Cargo
col_cargo_unico <- unique(col_cargo)
print(col_cargo_unico)

#Normalizando colunas cargos com aprox. 10 valores
normalizar_cargos <- function(cargos) {
  r <- cargos |>
    str_squish() |>
    str_to_lower()

  out <- rep("OUTROS", length(r))
  is_out <- function() out == "OUTROS"

  out[ is_out() & str_detect(r, "\\b(desembargador|juiz)\\b") ] <- "MAGISTRADO"
  out[ is_out() & str_detect(r, "oficial de justi[cç]a") ]      <- "OFICIAL DE JUSTIÇA"
  out[ is_out() & str_detect(r, "^esc\\.|\\bescriv") ]          <- "ESCRIVÃO"
  out[ is_out() & str_detect(r, "\\banalista\\b") ]             <- "ANALISTA"
  out[ is_out() & str_detect(r, "\\bt[eé]cnic[oa]\\b|t[eé]cnico judici[aá]rio") ] <- "TÉCNICO"
  out[ is_out() & str_detect(r, "psicolog|servi[cç]o social|assistente social") ] <- "SAÚDE/PSICOSSOCIAL"
  out[ is_out() & str_detect(r, "seguran") ]                    <- "SEGURANÇA"
  out[ is_out() & str_detect(r, "estagi") ]                     <- "ESTAGIÁRIO"
  out[ is_out() & str_detect(r, "assessor|assistente de gabinete|oficial de gabinete|gabinete|chefe|coordenador|diretor|secretar|requisitad") ] <- "ASSESSORIA/COMISSIONADO"
  out[ is_out() & str_detect(r, "auxiliar|ajudante|depositar") ]<- "AUXILIAR/OPERACIONAL"
 
  # Caixa alta para padronizar
  toupper(out)
}

cargos_norm <- normalizar_cargos(colunas_csv$Cargo)
cargos_norm_unico <- unique(cargos_norm)
print(cargos_norm_unico)