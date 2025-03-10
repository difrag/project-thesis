# Εφαρμογή Server
function(input, output) {
  
  # Reactive data storage (φόρτωμα δεδομένων)
  data <- reactive({
    req(input$file)
    read_csv(input$file$datapath)
  })
  
  # Target variable selection (dynamically created)
  output$target_ui <- renderUI({
    req(data())
    print(names(data()))  # Debug: List the columns to confirm
    selectInput("target", "Select Target Variable", names(data()))
  })
  
  # Συνάρτηση προεπεξεργασίας
  preprocessor <- reactive({
    req(data(), input$target)
    
    recipe(data) %>%
      update_role(!!sym(input$target), new_role = "outcome") %>%
      step_impute_median(all_numeric(), -has_role("outcome")) %>%
      step_impute_mode(all_nominal(), -has_role("outcome")) %>%
      step_normalize(all_numeric(), -has_role("outcome")) %>%
      step_dummy(all_nominal(), -has_role("outcome")) %>%
      step_select(top_p = input$top_features, 
                  score = function(x) {
                    cor_matrix <- cor(select(x, where(is.numeric)))
                    return (cor_matrix)
                  },
                  type = "score")
  })
  
  # Μοντέλο
  model <- reactive({
    switch(input$model_type,
           "rf" = rand_forest(mode = "classification",
                              engine = "ranger",
                              trees = 50,
                              mtry = floor(sqrt(ncol(data())))),
           "logreg" = logistic_reg(mode = "classification",
                                   engine = "glm"))
  })
  
  # Ανάλυση και εκπαίδευση του μοντέλου
  results <- eventReactive(input$run, {
    print("Running the analysis...")  # Debugging line to check if function is triggered
    req(data(), input$target, preprocessor(), model())
    
    # Διαχείριση κενών τιμών
    df <- data() %>% drop_na(!!sym(input$target))
    print("Data after NA removal:")
    # Αν το dataset είναι μεγάλο, χρησιμοποιούμε τα πρώτα 10k δείγματα
    if(nrow(df) > 10000) {
      showFeedbackWarning("file", "Using first 10k rows")
      df <- df %>% slice_sample(n = 10000)
    }
    
    # Διαχωρισμός σε train και test set
    split <- initial_split(df, prop = 0.8)
    train <- training(split)
    test <- testing(split)
    
    # Δημιουργία workflow
    wf <- workflow() %>%
      add_recipe(preprocessor()) %>%
      add_model(model())
    
    # Εκπαίδευση μοντέλου
    fit <- wf %>% fit(data = train)
    
    # Αξιολόγηση του μοντέλου
    pred <- predict(fit, new_data = test) %>% 
      bind_cols(test %>% select(!!sym(input$target)))
    
    print("Analysis complete!")  # Another debug line
    
    # Επιστροφή αποτελεσμάτων
    list(
      metrics = metric_set(accuracy)(pred, truth = !!sym(input$target), estimate = .pred_class),
      features = fit %>% extract_fit_parsnip() %>% vip::vi(),
      conf_mat = conf_mat(pred, truth = !!sym(input$target), estimate = .pred_class)
    )
  })
  
  # Outputs
  output$preview <- renderDT({
    datatable(head(data(), 100), options = list(scrollX = TRUE))
  })
  
  output$metrics <- renderPrint({
    results()$metrics
  })
  
  output$feature_plot <- renderPlot({
    feature_data <- results()$features
    if (nrow(feature_data) > 0) {
      ggplot(feature_data, aes(x = Importance, y = reorder(Variable, Importance))) +
        geom_col() +
        labs(y = "Features")
    } else {
      print("No feature importance data available")
    }
  })
  output$conf_matrix <- renderPrint({
    results()$conf_mat
  })
}
