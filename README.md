NOW UPDATED: Availability Automation

This serves to take the athlete-centric data, aggregate into a table, and distribute to coaches and staff everyday at a set time.

send_update_script : checks to see if the time to push for each group falls in a given window. If the time falls in the set frame (+/- 15 minutes from time 
of run), and if the group in the time frame does not already have data uploaded for that timeframe. then it will execute the alpine_availability_automation
script. 

alpine_availability_automation : Pulls data for all athletes in a specific group, calculates the amount of time since last update, aggregates data into a single
upload user table, and then inserts the data back into SB under "Availability Email Push." All data is uploaded against user "Alpine Availability API."

Forms on SB: Availability Form, Availability Email Push, Availability Send Times

Workflow to add a new group:
On Smartabase: ensure all the coaches/pt/staff have access to enter Data into "Availability Form"
     -1) Availability Form: ensure all the coaches/pt/staff have access to enter Data into "Availability Form"
     -2) Availability Send Times: Copy and Paste the group name EXACTLY into the 'group' field, select time for alert to go out in 'question' field
     -3) Ensure that the Alpine Availability API account has COACH and ATHLETE access to the group you are adding 
     -4) RUN action
     -5) Ensure that the group is inserted into SB 
           - run a report on "Availability Email Push" and be sure that group is populating with data
     -6) Set up a Performance Alert for the new group
           - Naming Connotation: *SPORT* Availability Update - *SPECIFIC GROUP*
           - add a filter setting group = to new group
           - Message: "Daily Status of *SPORT* Availability - *SPECIFIC GROUP*
           See PDF for details!"
