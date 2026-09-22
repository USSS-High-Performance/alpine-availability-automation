library(smartabaseR)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(dotenv)

#Set action to run every 10 minutes so the sync lines up

url <- "usopc.smartabase.com/athlete360-usss"
username <- Sys.getenv("SB_USERNAME")
password <- Sys.getenv("SB_PASSWORD")

current_time <- Sys.time()
min_window <- current_time - 900
max_window <- current_time + 900

# seconds since midnight
tod <- function(x) as.numeric(format(x, "%H")) * 3600 +
  as.numeric(format(x, "%M")) * 60

now_tod <- tod(current_time)
min_tod <- now_tod - 900
max_tod <- now_tod + 900


source_form_1 <- 'Alpine Availability Send Times'
email_form   <- 'Alpine Availability Email Push'

upload_user_id <- 27306

today_str <- format(Sys.Date(), "%d/%m/%Y")

#getting the data
fetch_source_data_1 <- function() {
  sb_get_event(
    form       = source_form_1,
    date_range = c("01/01/2026", today_str),
    url        = url,
    username   = username,
    password   = password,
    filter = sb_get_event_filter(user_key = "current_group")
  )
}
source_data <- fetch_source_data_1()
print(source_data)

#Setting up time in zone and as a date/time variable
event_time <- as.POSIXct(source_data$Question,
                         format = "%H:%M", tz = "America/Denver")
event_tod  <- tod(event_time)
print(data.frame(group = source_data$`Pod/Group Name`,
                 sched = format(event_time, "%H:%M")))

print(event_time)

# already pushed in this window
prior_pushes <- sb_get_event(
  form       = email_form,
  date_range = c("01/01/2026", today_str),
  url = url, 
  username = username, 
  password = password
)
print(prior_pushes)

push_time <- as.POSIXct(
  paste(prior_pushes$start_date, prior_pushes$start_time),
  format = "%d/%m/%Y %I:%M %p", tz = "America/Denver"
)

pushed <- prior_pushes$Group[!is.na(prior_pushes$Group) &
                               !is.na(push_time) &
                               push_time > min_window &
                               push_time < max_window]

#debugging
cat("---- DEBUG ----\n")
print(Sys.time())
print(Sys.timezone())
print(Sys.getlocale("LC_TIME"))
print(nrow(source_data))
print(c(min_tod = min_tod, max_tod = max_tod))
print(head(event_tod, 10))
print(sum(!is.na(event_tod)))
print(c(min_window, max_window))
print(pushed)
print(sum(!is.na(event_tod) & event_tod > min_tod & event_tod < max_tod))
cat("---------------\n")


#Creating specific time window variable
window <- !is.na(event_tod) & event_tod > min_tod & event_tod < max_tod &
  !(source_data$`Pod/Group Name` %in% pushed)

in_time    <- source_data[window, ]
group_name <- unique(as.character(in_time$`Pod/Group Name`))
print(group_name)

for (grp in group_name) {
  current_group <- grp
  message("Processing: ", current_group)
  try(source("alpine_availability_automation.R"))
}
