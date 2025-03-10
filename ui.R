# Εφαρμογή UI

library(shinyFeedback)

fluidPage(
  useShinyFeedback(), # Για feedback χρήστη
  titlePanel("Medical Data Analysis Pipeline"),
  
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload medical dataset (CSV)", accept = ".csv"),
      uiOutput("target_ui"), # Target selection (rendered dynamically)
      selectInput("model_type", "Select Model",
                  choices = c("Random Forest" = "rf", 
                              "Logistic Regression" = "logreg")),
      numericInput("top_features", "Number of Top Features", 
                   value = 50, min = 1, max = 100),
      actionButton("run", "Run Analysis")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Data Preview", DTOutput("preview")),
        tabPanel("Analysis",
                 h3("Model Performance"),
                 verbatimTextOutput("metrics"),
                 h3("Feature Importance"),
                 plotOutput("feature_plot"),
                 h3("Confusion Matrix"),
                 verbatimTextOutput("conf_matrix"))
      )
    )
  )
)
