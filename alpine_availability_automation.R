library(smartabaseR)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(dotenv)

url <- "usopc.smartabase.com/athlete360-usss"
username <- Sys.getenv("SB_USERNAME")
password <- Sys.getenv("SB_PASSWORD")
  
source_form <- 'Availability Form'
target_form <- 'Availability Email Push'

upload_user_id <- 27306
  
today_str <- format(Sys.Date(), "%d/%m/%Y")

#get data
fetch_source_data <- function() {
  sb_get_event(
    form       = source_form,
    date_range = c("01/01/2026", today_str),
    url        = url,
    username   = username,
    password   = password,
    filter = sb_get_event_filter(user_key = "group",
    user_value = current_group)
  )
}
print(fetch_source_data())

#slice
latest_per_athlete <- function(data) {
  data %>%
    group_by(Athlete) %>%
    slice_max(order_by = event_id, n = 1) %>%
    ungroup()
}

#date manipulation
add_days_since_record <- function(data) {
  data %>%
    mutate(
      record_date    = as.Date(start_date, format = "%d/%m/%Y"),
      days_since     = as.integer(Sys.Date() - record_date),
      `Last Updated` = paste0(days_since, " days ago")
    )
}

#Combined Pull and Slice
get_source_data_v3 <- function() {
  fetch_source_data() %>%
    latest_per_athlete() %>%
    add_days_since_record()
}

source_data <- get_source_data_v3()
#glimpse(source_data) - check data

#STEP 2 - MANIPULATE
#manipulate into target table shape
manipulated_data <- source_data %>%
  transmute(
    #target form field names                             = #source form field names
    `Athlete`                                            = `Athlete`,
    `Availability`                                       = `Availability`,
    `Notes`                                              = `Brief Notes (Optional)`,
    `Group`                                              =  current_group,
    `Last Updated`                                       =  `Last Updated`   
  ) %>%
  arrange(`Athlete`)

#glimpse(manipulated_data) - check data

#STEP 3 - PUSH DATA
upload_data <- manipulated_data %>%
  mutate(
    user_id    = upload_user_id,   # same for every row -> triggers table grouping
    start_date = today_str
  ) %>%
  select(user_id, start_date, everything())

#glimpse(upload_data) - check data


sb_insert_event(
  df       = upload_data,
  form     = target_form,
  url      = url,
  username = username,
  password = password,
  option   = sb_insert_event_option(
  table_field = c("Athlete", "Availability", "Notes", "Group", "Last Updated")
  )
)
