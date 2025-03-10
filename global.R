# Φόρτωση βιβλιοθηκών
library(shiny)
library(tidymodels)
library(tidyverse)
library(DT)
library(skimr)
library(shinyFeedback)

options(shiny.maxRequestSize = 100 * 1024^2)  # Set max upload size to 100 MB

# Συνάρτηση φόρτωσης δεδομένων (προαιρετικό)
load_data <- function(file_path) {
  return(read.csv(file_path))
}

# Συνάρτηση προεπεξεργασίας (προαιρετικό)
preprocess_data <- function(data) {
  # Εδώ θα βάλεις τις διαδικασίες προεπεξεργασίας που θες
}
