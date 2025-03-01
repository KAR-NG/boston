#--------------------------------------------------------------------------
# Import libraries --------------------------------------------------------
#--------------------------------------------------------------------------

library(shiny)
library(data.table)
library(randomForest)
library(shinythemes)
library(tidyverse)


#--------------------------------------------------------------------------
# Read in the model -------------------------------------------------------
#--------------------------------------------------------------------------

model_rf <- readRDS("boston_rf_model.rds")

train_data <- read.csv("train.csv", header = T)

#--------------------------------------------------------------------------
# User Interface  ---------------------------------------------------------
#--------------------------------------------------------------------------


ui <- fluidPage(theme = shinytheme("cyborg"),
  
  # Page header
  navbarPage("Boston Median House Prices Predictor",
  
  # Input values
  tabPanel("Home",
           sidebarPanel(
             tags$label(h3("Input Features")),
             selectInput(inputId = "charles.river", 
                      label = "Charles River", 
                      choices = list("Yes" = 1, "No" = 0)),
             sliderInput(inputId = "crime.rate",
                          label = "Crime Rate",
                          value = 1,
                          min = min(train_data$crime.rate),
                          max = max(train_data$crime.rate)),
             sliderInput(inputId = "resid.zone", 
                         label = "Residential Zone",
                         value = 1, 
                         min = min(train_data$resid.zone),
                         max = max(train_data$resid.zone)),
             sliderInput(inputId = "indus.biz", 
                         label = "Non-retail business",
                         value = 1,
                         min = min(train_data$indus.biz),
                         max = max(train_data$indus.biz)),
            sliderInput(inputId = "nitrogen.oxide", 
                        label = "Nitrogen Oxide Concentration",
                        value = 0.4,
                        min = min(train_data$nitrogen.oxide),
                        max = max(train_data$nitrogen.oxide)
                           ),
            numericInput(inputId = "room", 
                         label = "Room",
                         value = 0),
            numericInput(inputId = "age", 
                         label = "Age",
                         value = 0),
            numericInput(inputId = "dist.to.work", 
                         label = "Distance to Employment Center",
                         value = 0),
            numericInput(inputId = "highway.index", 
                         label = "Radial highways Accessibility",
                         value = 0),
            numericInput(inputId = "property.tax", 
                         label = "Property Tax",
                         value = 0),
            numericInput(inputId = "pt.ratio", 
                         label = "Pupil-teacher ratio",
                         value = 0),
            numericInput(inputId = "black", 
                         label = "Black Community Proportion",
                         value = 0),
            numericInput(inputId = "lstat", 
                         label = "Lower Status Proportion",
                         value = 0),
            actionButton("SubmitButton", "Submit", class = "btn btn-primary")),
           
           # main panel
           mainPanel(
             tags$label(h3("Status")),
             verbatimTextOutput("contents"),
             tableOutput("tabledata"))
           ), # tab panel Home 
  
  tabPanel("About",
           div(includeMarkdown("about.md"),
               align = "justify")
           ) # tab panel About
  ) # navbarPage 
)# fluidPage 


#--------------------------------------------------------------------------
# Server ------------------------------------------------------------------
#--------------------------------------------------------------------------

server <- function(input, output, session) {
  
  myprediction <- reactive({
    
    # set up df
    df <- data.frame(
      Name = c("charles.river",
               "crime.rate",
               "resid.zone",
               "indus.biz",
               "nitrogen.oxide",
               "room",
               "age",
               "dist.to.work",
               "highway.index",
               "property.tax",
               "pt.ratio",
               "black",
               "lstat"),
      value = as.character(c(input$charles.river,
                             input$crime.rate,
                             input$resid.zone,
                             input$indus.biz,
                             input$nitrogen.oxide,
                             input$room,
                             input$age,
                             input$dist.to.work,
                             input$highway.index,
                             input$property.tax,
                             input$pt.ratio,
                             input$black,
                             input$lstat)),
      stringsAsFactors = F)
    
    # add in one empty y for predict by row bind. 
    house.value <- 0
    df <- rbind(df, house.value)
    
    # pivot wider by transpose
    df2 <- df %>% pivot_wider(names_from = Name, values_from = value)
    
    # Save it into local file
    write.csv(df2, "Shiny_InputValues.csv", row.names = F)
    
    # Read it back into R 
    new.test.set <- read.csv("Shiny_InputValues.csv", header = T)
    
    new.test.set <- new.test.set %>% 
      mutate(charles.river = as.factor(charles.river),
             crime.rate = as.double(crime.rate),
             resid.zone = as.double(resid.zone),
             indus.biz = as.double(indus.biz),
             nitrogen.oxide = as.double(nitrogen.oxide),
             room = as.double(room),
             age = as.double(age),
             dist.to.work = as.double(dist.to.work),
             highway.index = as.double(highway.index),
             property.tax = as.double(property.tax),
             pt.ratio = as.double(pt.ratio),
             black = as.double(black),
             lstat = as.double(lstat),
             house.value = as.double(house.value)
             ) 
 
    # Prediction using the Random Forest Model
    Output <- data.frame(Prediction = predict(model_rf, new.test.set))
    print(Output)
    
  })     # Close myprediction
  
  
  # Status Test Reaction
  output$contents <- renderPrint({
    if(input$SubmitButton > 0){
      isolate("Prediction complete.")
    } else {
      return("Waiting for you to press the Submit Button.")
    }
  })
  
  # Prediction results table
  output$tabledata <- renderTable({
    if(input$SubmitButton > 0){
      isolate(myprediction())
    }
  })
  
  
}

#--------------------------------------------------------------------------
# running the app ---------------------------------------------------------
#--------------------------------------------------------------------------

shinyApp(ui, server)