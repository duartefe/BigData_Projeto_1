# app.R — Dashboard Servidores TJ (09/2024 a 08/2025)
# Rodar a partir de: projeto/dashboard/app.R

# ---- Pacotes ----
packages <- c(
  "shiny","shinydashboard","shinyWidgets","DT","dplyr","tidyr",
  "readr","stringr","lubridate","janitor","purrr","plotly","scales"
)
not_installed <- packages[!packages %in% rownames(installed.packages())]
if (length(not_installed) > 0) install.packages(not_installed, dependencies = TRUE)
invisible(lapply(packages, library, character.only = TRUE))

options(scipen = 999)

# ---- Configurações de paths ----
pasta_raiz <- ".."  # volta para projeto/
pastas_normalizadas <- c(
  file.path(pasta_raiz, "tjrn-csv", "dados_normalizados"),
  file.path(pasta_raiz, "tjgo-xlsx", "dados_normalizados"),
  file.path(pasta_raiz, "tjro-xml", "dados_normalizados")
)

# Intervalo alvo: 2024-09 a 2025-08
competencia_ini <- as.Date("2024-09-01")
competencia_fim <- as.Date("2025-08-01")

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

# ---- Funções utilitárias ----
infer_tj <- function(prefix) {
  pref <- toupper(prefix)
  if (pref == "RN") return("TJRN")
  if (pref == "GO") return("TJGO")
  if (pref == "RO") return("TJRO")
  paste0("TJ", pref)
}

infer_competencia_from_name <- function(fname) {
  base <- tolower(tools::file_path_sans_ext(basename(fname)))
  # casa rn0924_norm  ou  rn0924
  m <- stringr::str_match(base, "^([a-z]{2})(\\d{4})(?:_norm)?$")
  if (is.na(m[1,1])) return(list(tj = NA_character_, competencia = as.Date(NA)))
  uf <- m[1,2]; mmyy <- m[1,3]
  mm <- as.integer(substr(mmyy, 1, 2))
  yy <- as.integer(substr(mmyy, 3, 4))
  ano <- 2000 + yy
  comp <- suppressWarnings(as.Date(sprintf("%04d-%02d-01", ano, mm)))
  list(tj = infer_tj(uf), competencia = comp)
}

listar_arquivos <- function(pastas) {
  files <- purrr::map(pastas, ~list.files(.x, pattern = "\\.csv$", full.names = TRUE)) %>% unlist()
  # aceita: xxMMYY_norm.csv (e também xxMMYY.csv, se aparecer)
  keep <- stringr::str_detect(tolower(basename(files)), "^[a-z]{2}\\d{4}(?:_norm)?\\.csv$")
  files[keep]
}

ler_csv_norm <- function(path) {
  df <- suppressWarnings(readr::read_delim(
    path, delim = ";", locale = locale(decimal_mark = ","),
    show_col_types = FALSE, progress = FALSE
  ))
  df <- janitor::clean_names(df)
  col_nome  <- names(df)[stringr::str_detect(names(df), "^nome$")] %||% NA
  col_cargo <- names(df)[stringr::str_detect(names(df), "^cargo$")] %||% NA
  col_liq   <- names(df)[stringr::str_detect(names(df), "rendimento.*liquid|remuneracao.*liquid|liq")] %||% NA

  to_num <- function(x) {
    x <- as.character(x); x <- gsub("\\.", "", x); x <- gsub(",", ".", x)
    suppressWarnings(as.numeric(x))
  }

  liq <- if (!is.na(col_liq[1])) to_num(df[[col_liq[1]]]) else NA_real_
  # heurística de escala (se mediana > 200k, divide por 100 no arquivo)
  med <- suppressWarnings(stats::median(liq, na.rm = TRUE))
  scale <- if (!is.na(med) && med > 200000) 0.01 else 1.0
  liq <- liq * scale

  meta <- infer_competencia_from_name(path)

  tibble::tibble(
    Tribunal = meta$tj,
    Competencia = meta$competencia,
    Nome = if (!is.na(col_nome[1])) as.character(df[[col_nome[1]]]) else NA_character_,
    Cargo = if (!is.na(col_cargo[1])) as.character(df[[col_cargo[1]]]) else NA_character_,
    Remuneracao = liq
  )
}

# ---- Carregamento de dados ----
arquivos <- listar_arquivos(pastas_normalizadas)
if (length(arquivos) == 0) stop("Nenhum CSV xxMMYY_norm.csv encontrado nas pastas dados_normalizados.")

dados_master <- purrr::map_dfr(arquivos, ler_csv_norm)
if (!"Competencia" %in% names(dados_master)) stop("Coluna 'Competencia' não foi gerada.")

dados_master <- dados_master %>%
  dplyr::mutate(Competencia = as.Date(Competencia)) %>%
  dplyr::filter(!is.na(Competencia)) %>%
  dplyr::filter(Competencia >= competencia_ini, Competencia <= competencia_fim) %>%
  dplyr::mutate(Nome = stringr::str_squish(Nome), Cargo = stringr::str_squish(Cargo))

tribunais_disp <- sort(unique(dados_master$Tribunal))

# ---- UI ----
ui <- dashboardPage(
  dashboardHeader(title = "Visão Geral — Servidores TJ (09/2024 a 08/2025)"),
  dashboardSidebar(
    pickerInput("tribunal", "Tribunal:", choices = tribunais_disp,
                selected = tribunais_disp, multiple = TRUE,
                options = list(`actions-box` = TRUE, `live-search` = TRUE)),
    uiOutput("ui_cargo"),
    dateRangeInput("periodo", "Período:", start = competencia_ini, end = competencia_fim,
                   min = competencia_ini, max = competencia_fim, format = "mm/yyyy"),
    numericInput("teto", "Teto (R$):", value = 44000, min = 0, step = 100),
    textInput("servidor", "Buscar servidor (nome contém):", "")
  ),
  dashboardBody(
    tabsetPanel(
      tabPanel("Visão Geral",
        fluidRow(
          valueBoxOutput("kpi_total_servidores", width = 3),
          valueBoxOutput("kpi_media", width = 3),
          valueBoxOutput("kpi_mediana", width = 3),
          valueBoxOutput("kpi_excedentes", width = 3)
        ),
        fluidRow(
          box(width = 6, title = "Distribuição da Remuneração (Histograma)", solidHeader = TRUE, status = "primary",
              plotlyOutput("dist_hist", height = 320)),
          box(width = 6, title = "Distribuição por Cargo (Boxplot — top 10)", solidHeader = TRUE, status = "primary",
              plotlyOutput("dist_box", height = 320))
        ),
        fluidRow(
          box(width = 12, title = "Servidores por Função (Top 20)", solidHeader = TRUE, status = "primary",
              DTOutput("tabela_por_funcao"))
        )
      ),
      tabPanel("Maior Remuneração — Últimos 12 meses",
        fluidRow(
          box(width = 12, title = "Top remuneração mensal por servidor (últimos 12 meses)", solidHeader = TRUE, status = "primary",
              DTOutput("tabela_top_remun"))
        )
      ),
      tabPanel("Teto & Impacto",
        fluidRow(
          valueBoxOutput("kpi_qtd_acima_teto", width = 4),
          valueBoxOutput("kpi_impacto_total", width = 4),
          valueBoxOutput("kpi_carreira_impacto", width = 4)
        ),
        fluidRow(
          box(width = 12, title = "Impacto por Cargo", solidHeader = TRUE, status = "primary",
              DTOutput("tabela_impacto"), downloadButton("download_impacto", "Baixar CSV"))
        )
      ),
      tabPanel("Variação Remuneratória",
        fluidRow(
          box(width = 6, title = "Ranking por Servidor (Δ máx − mín no período)", solidHeader = TRUE, status = "primary",
              DTOutput("rank_variacao_servidor")),
          box(width = 6, title = "Ranking por Cargo (Δ de média e mediana no período)", solidHeader = TRUE, status = "primary",
              DTOutput("rank_variacao_cargo"))
        )
      ),
      tabPanel("Trajetórias",
        fluidRow(
          box(width = 6, title = "Trajetória por Servidor", solidHeader = TRUE, status = "primary",
              plotlyOutput("traj_servidor", height = 320)),
          box(width = 6, title = "Trajetória por Cargo (média & mediana)", solidHeader = TRUE, status = "primary",
              plotlyOutput("traj_cargo", height = 320))
        )
      ),
      tabPanel("Análises Avançadas",
        fluidRow(
          box(width = 12, title = "Folha total mensal (R$)", solidHeader = TRUE, status = "primary",
              plotlyOutput("folha_total_mensal", height = 320))
        ),
        fluidRow(
          box(width = 6, title = "Média por TJ ao longo do tempo", solidHeader = TRUE, status = "primary",
              plotlyOutput("media_por_tj", height = 320)),
          box(width = 6, title = "Excedentes ao teto por mês (quantidade e impacto total)", solidHeader = TRUE, status = "primary",
              plotlyOutput("excedentes_por_mes", height = 320))
        )
      ),
      tabPanel("Dados (Auditoria)",
        fluidRow(
          box(width = 12, title = "Tabela filtrada", solidHeader = TRUE, status = "primary",
              DTOutput("tabela_dados"))
        )
      )
    )
  )
)

# ---- Server ----
server <- function(input, output, session) {

  # Cargo choices reativos por tribunal
  output$ui_cargo <- renderUI({
    cargos <- dados_master %>%
      dplyr::filter(Tribunal %in% input$tribunal) %>%
      dplyr::pull(Cargo) %>% unique() %>% sort()
    pickerInput("cargo", "Cargo:", choices = cargos, multiple = TRUE,
                options = list(`actions-box` = TRUE, `live-search` = TRUE))
  })

  dados_filtrados <- reactive({
    req(input$tribunal, input$periodo)
    df <- dados_master %>%
      dplyr::filter(
        Tribunal %in% input$tribunal,
        Competencia >= as.Date(input$periodo[1]),
        Competencia <= as.Date(input$periodo[2])
      )
    if (!is.null(input$cargo) && length(input$cargo) > 0) df <- df %>% dplyr::filter(Cargo %in% input$cargo)
    if (nzchar(input$servidor)) df <- df %>% dplyr::filter(stringr::str_detect(Nome, regex(input$servidor, ignore_case = TRUE)))
    df
  })

  # ---- KPIs visão geral ----
  output$kpi_total_servidores <- renderValueBox({
    df <- dados_filtrados()
    n <- df %>% dplyr::distinct(Nome) %>% nrow()
    valueBox(format(n, big.mark = ".", decimal.mark = ","), "Servidores distintos", icon = icon("users"), color = "teal")
  })
  output$kpi_media <- renderValueBox({
    df <- dados_filtrados()
    media <- mean(df$Remuneracao, na.rm = TRUE)
    valueBox(scales::dollar(media, prefix = "R$ ", big.mark = ".", decimal.mark = ","), "Média", icon = icon("chart-line"), color = "green")
  })
  output$kpi_mediana <- renderValueBox({
    df <- dados_filtrados()
    med <- median(df$Remuneracao, na.rm = TRUE)
    valueBox(scales::dollar(med, prefix = "R$ ", big.mark = ".", decimal.mark = ","), "Mediana", icon = icon("chart-area"), color = "olive")
  })
  output$kpi_excedentes <- renderValueBox({
    df <- dados_filtrados(); teto <- input$teto %||% 44000
    qtd <- sum(df$Remuneracao > teto, na.rm = TRUE)
    valueBox(format(qtd, big.mark = ".", decimal.mark = ","), "Acima do teto", icon = icon("exclamation-triangle"), color = "red")
  })

  # ---- Distribuições ----
  output$dist_hist <- renderPlotly({
    df <- dados_filtrados(); req(nrow(df) > 0)
    plot_ly(df, x = ~Remuneracao, type = "histogram") %>%
      layout(xaxis = list(title = "Remuneração líquida"), yaxis = list(title = "Frequência"))
  })
  output$dist_box <- renderPlotly({
    df <- dados_filtrados() %>% dplyr::filter(!is.na(Cargo)); req(nrow(df) > 0)
    top_cargos <- df %>% count(Cargo, sort = TRUE) %>% slice_head(n = 10) %>% pull(Cargo)
    df2 <- df %>% dplyr::filter(Cargo %in% top_cargos)
    plot_ly(df2, y = ~Remuneracao, x = ~Cargo, type = "box") %>%
      layout(xaxis = list(title = "Cargo"), yaxis = list(title = "Remuneração líquida"))
  })
  output$tabela_por_funcao <- renderDT({
    df <- dados_filtrados() %>% dplyr::group_by(Cargo) %>%
      dplyr::summarise(Servidores = n_distinct(Nome), .groups = "drop") %>% dplyr::arrange(desc(Servidores))
    datatable(df, options = list(pageLength = 20))
  })

  # ---- Maior remuneração último ano ----
  output$tabela_top_remun <- renderDT({
    df <- dados_filtrados(); req(nrow(df) > 0)
    ultimo_comp <- max(df$Competencia, na.rm = TRUE); ini_12m <- (ultimo_comp %m-% months(11))
    d12 <- df %>% dplyr::filter(Competencia >= ini_12m, Competencia <= ultimo_comp)
    top <- d12 %>% dplyr::group_by(Nome) %>%
      dplyr::slice_max(order_by = Remuneracao, n = 1, with_ties = FALSE) %>% dplyr::ungroup() %>%
      dplyr::mutate(RemunAux = Remuneracao) %>% dplyr::arrange(dplyr::desc(RemunAux)) %>%
      dplyr::mutate(Competencia = format(Competencia, "%m/%Y")) %>% dplyr::select(Nome, Cargo, Tribunal, Competencia, Remuneracao)
    datatable(top, options = list(pageLength = 20))
  })

  # ---- Teto & Impacto ----
  impacto_tbl <- reactive({
    df <- dados_filtrados(); teto <- input$teto %||% 44000
    df %>% dplyr::mutate(Excedente = pmax(Remunercao = Remuneracao - teto, 0)) %>%
      dplyr::group_by(Cargo) %>%
      dplyr::summarise(
        ImpactoTotal = sum(Excedente, na.rm = TRUE),
        ServidoresAfetados = dplyr::n_distinct(Nome[Excedente > 0]),
        ImpactoPerCapita = ifelse(ServidoresAfetados > 0, ImpactoTotal / ServidoresAfetados, 0),
        .groups = "drop"
      ) %>% dplyr::arrange(dplyr::desc(ImpactoTotal))
  })
  output$kpi_qtd_acima_teto <- renderValueBox({
    df <- dados_filtrados(); teto <- input$teto %||% 44000
    qtd <- df %>% dplyr::mutate(Exced = Remuneracao - teto) %>% dplyr::filter(Exced > 0) %>% nrow()
    valueBox(format(qtd, big.mark = ".", decimal.mark = ","), "Registros acima do teto", icon = icon("angle-up"), color = "maroon")
  })
  output$kpi_impacto_total <- renderValueBox({
    imp <- impacto_tbl() %>% summarise(t = sum(ImpactoTotal, na.rm = TRUE)) %>% pull(t)
    valueBox(scales::dollar(imp, prefix = "R$ ", big.mark = ".", decimal.mark = ","), "Impacto total", icon = icon("coins"), color = "purple")
  })
  output$kpi_carreira_impacto <- renderValueBox({
    tb <- impacto_tbl()
    if (nrow(tb) == 0) return(valueBox("—", "Carreira com maior impacto", icon = icon("user-tie"), color = "navy"))
    top <- tb %>% slice_max(order_by = ImpactoTotal, n = 1)
    txt <- paste0(top$Cargo, " (", scales::dollar(top$ImpactoTotal, prefix = "R$ ", big.mark = ".", decimal.mark = ","), ")")
    valueBox(txt, "Carreira com maior impacto", icon = icon("user-tie"), color = "navy")
  })
  output$tabela_impacto <- renderDT({
    tb <- impacto_tbl() %>% dplyr::mutate(
      ImpactoTotal = scales::dollar(ImpactoTotal, prefix = "R$ ", big.mark = ".", decimal.mark = ","),
      ImpactoPerCapita = scales::dollar(ImpactoPerCapita, prefix = "R$ ", big.mark = ".", decimal.mark = ",")
    )
    datatable(tb, options = list(pageLength = 20))
  })
  output$download_impacto <- downloadHandler(
    filename = function() "impacto_por_cargo.csv",
    content = function(file) { readr::write_csv(impacto_tbl(), file) }
  )

  # ---- Variação ----
  output$rank_variacao_servidor <- renderDT({
    df <- dados_filtrados() %>% dplyr::group_by(Nome) %>%
      dplyr::summarise(Variacao = max(.data$Remuneracao, na.rm = TRUE) - min(.data$Remuneracao, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(Variacao)) %>% dplyr::slice_head(n = 50)
    df$Variacao <- scales::dollar(df$Variacao, prefix = "R$ ", big.mark = ".", decimal.mark = ",")
    datatable(df, options = list(pageLength = 20))
  })
  output$rank_variacao_cargo <- renderDT({
    df <- dados_filtrados() %>% dplyr::group_by(Competencia, Cargo) %>%
      dplyr::summarise(Media = mean(.data$Remuneracao, na.rm = TRUE), Mediana = median(.data$Remuneracao, na.rm = TRUE), .groups = "drop") %>%
      dplyr::group_by(Cargo) %>%
      dplyr::summarise(DeltaMedia = max(Media, na.rm = TRUE) - min(Media, na.rm = TRUE),
                       DeltaMediana = max(Mediana, na.rm = TRUE) - min(Mediana, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(dplyr::desc(DeltaMedia))
    df$DeltaMedia   <- scales::dollar(df$DeltaMedia,   prefix = "R$ ", big.mark = ".", decimal.mark = ",")
    df$DeltaMediana <- scales::dollar(df$DeltaMediana, prefix = "R$ ", big.mark = ".", decimal.mark = ",")
    datatable(df, options = list(pageLength = 20))
  })

  # ---- Trajetórias ----
  output$traj_servidor <- renderPlotly({
    req(nzchar(input$servidor))
    df <- dados_filtrados() %>%
      dplyr::filter(stringr::str_detect(Nome, regex(input$servidor, ignore_case = TRUE))) %>%
      dplyr::group_by(Nome, Competencia) %>%
      dplyr::summarise(Remed = mean(.data$Remuneracao, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(Competencia)
    plot_ly(df, x = ~Competencia, y = ~Remed, color = ~Nome, type = "scatter", mode = "lines+markers") %>%
      layout(yaxis = list(title = "R$"), xaxis = list(title = "Competência"))
  })
  output$traj_cargo <- renderPlotly({
    df <- dados_filtrados()
    if (!is.null(input$cargo) && length(input$cargo) > 0) df <- df %>% dplyr::filter(Cargo %in% input$cargo)
    serie <- df %>% dplyr::group_by(Competencia) %>%
      dplyr::summarise(Media = mean(.data$Remuneracao, na.rm = TRUE), Mediana = median(.data$Remuneracao, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(Competencia)
    plot_ly(serie, x = ~Competencia, y = ~Media, name = "Média", type = "scatter", mode = "lines") %>%
      add_trace(y = ~Mediana, name = "Mediana", mode = "lines") %>%
      layout(yaxis = list(title = "R$"), xaxis = list(title = "Competência"))
  })

  # ---- Análises Avançadas ----
  output$folha_total_mensal <- renderPlotly({
    df <- dados_filtrados() %>% dplyr::group_by(Competencia) %>%
      dplyr::summarise(FolhaTotal = sum(.data$Remuneracao, na.rm = TRUE), Servidores = n_distinct(Nome), .groups = "drop") %>%
      dplyr::arrange(Competencia)
    plot_ly(df, x = ~Competencia, y = ~FolhaTotal, type = "scatter", mode = "lines+markers",
            text = ~paste0("Servidores: ", Servidores), hoverinfo = "text+y+x") %>%
      layout(yaxis = list(title = "R$"), xaxis = list(title = "Competência"))
  })
  output$media_por_tj <- renderPlotly({
    df <- dados_filtrados() %>% dplyr::group_by(Competencia, Tribunal) %>%
      dplyr::summarise(Media = mean(.data$Remuneracao, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(Competencia)
    plot_ly(df, x = ~Competencia, y = ~Media, color = ~Tribunal, type = "scatter", mode = "lines") %>%
      layout(yaxis = list(title = "R$ (média)"), xaxis = list(title = "Competência"))
  })
  output$excedentes_por_mes <- renderPlotly({
    teto <- input$teto %||% 44000
    df <- dados_filtrados() %>% dplyr::mutate(Exced = pmax(.data$Remuneracao - teto, 0)) %>%
      dplyr::group_by(Competencia) %>%
      dplyr::summarise(QtdAcima = sum(Exced > 0, na.rm = TRUE), ImpactoTotal = sum(Exced, na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(Competencia)
    # duas séries: barra para quantidade e linha para impacto
    p <- plot_ly(df, x = ~Competencia, y = ~QtdAcima, type = "bar", name = "Qtd. acima do teto")
    p <- add_trace(p, y = ~ImpactoTotal, type = "scatter", mode = "lines+markers", name = "Impacto total (R$)", yaxis = "y2")
    p %>% layout(
      xaxis = list(title = "Competência"),
      yaxis = list(title = "Quantidade"),
      yaxis2 = list(title = "Impacto (R$)", overlaying = "y", side = "right")
    )
  })

  # ---- Dados (Auditoria) ----
  output$tabela_dados <- renderDT({
    df <- dados_filtrados() %>%
      dplyr::mutate(
        Competencia = format(Competencia, "%m/%Y"),
        Remuneracao = scales::dollar(.data$Remuneracao, prefix = "R$ ", big.mark = ".", decimal.mark = ",")
      ) %>% dplyr::select(Tribunal, Competencia, Nome, Cargo, Remuneracao)
    datatable(df, options = list(pageLength = 25))
  })
}

shinyApp(ui, server)
