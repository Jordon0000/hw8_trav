#!/usr/bin/bash

# HW8 - Guis with Dialog
# 11/26/2026
# CSE 224
# Group Members: 
#   Jordon Williams-McKinnon
#   Evan Payne

# city_menu function
# Takes two parameters: a string for menu text, and an array
city_menu ()
{
	local menutext=$1
	local -n array=$2
	# By using ${#array[@]} the size of the list will vary depending on the length of the array
	dialog --keep-tite --no-cancel --title "Reservation Manager" --output-fd 1 --no-items --menu "$menutext" 0 0 ${#array[@]} "${array[@]}" 
}

# reservation_confirm function
# Takes one parameter: reservation information (in the res.txt format)
reservation_confirm ()
{
	local -n info=$1
	local prefix=$2

	local info_name=$(echo "$info" | awk -F'|' '{print $1}')
	local info_bags=$(echo "$info" | awk -F'|' '{print $2}')
	local info_deptcity=$(echo "$info" | awk -F'|' '{print $3}')
	local info_destcity=$(echo "$info" | awk -F'|' '{print $4}')
	local info_deptdate=$(echo "$info" | awk -F'|' '{print $5}')
	local info_retndate=$(echo "$info" | awk -F'|' '{print $6}')
	
	local msg="$prefix\n\n\
	Name: $info_name\n\
	Amount of Checked Bags: $info_bags\n\
	Departure City: $info_deptcity\n\
	Destination City: $info_destcity\n\
	Departure Date: $info_deptdate\n\
	Return Date: $info_retndate"
	dialog --keep-tite --title "Reservation Manager - Confirm Info" --yesno "$msg" 0 0
	# "$name|$bags|$departure_city|$destination_city|$departure_date|$return_date"
}

# Create the res.txt file if not already created
touch res.txt

# Create a list of valid cities that can be chosen
cities=()
cities[1]="Tokyo"
cities[2]="Osaka"
cities[3]="Kyoto"
cities[4]="Fukusaki"
cities[5]="Tottori"
cities[6]="Hiroshima"
cities[7]="Hito"

## START OF DISPLAY MESSAGES
invalid_input=0 # Flag used to detect if the user's input was invalid


# Get the user's name using an input box.
# The name is also checked for any illegal characters ("|")
# If any are found, then the user is reprompted to enter their name again.
while true
do
    if [[ $invalid_input -eq 1 ]]
	then
        dialog --keep-tite --title "Reservation Manager - Error" --msgbox "Invalid name: cannot contain any invalid characters!" 0 0
	fi

	name=$(dialog --keep-tite --no-cancel --title "Reservation Manager" --output-fd 1 --inputbox "Enter your name:" 0 0) # --output-fd 1 will store the output from stdout in name


	invalid_input=1
	if [[ "$name" =~ [|\\/$^_+=\-\`\~] ]]
	then
		continue
	fi

	invalid_input=0 # Reset the failure flag 

	break
done

# Check if there's already a reservation for this user.
# If there is, double check if they want to keep it or replace it
# with a new reservation.
# Meets additional feature #4!
reservation_info=$(grep "^$name|" res.txt)
if [[ $reservation_info ]]
then
	# There is!
	# Now see if the user wants to keep or replace their current reservation
	
	reservation_confirm reservation_info "Found existing reservation! Do you wish\nto delete it and create a new one?"

	response=$?
	if [[ $response -eq 1 ]] 
	then
		dialog --keep-tite --title "Reservation Manager" --msgbox "No changes will be made. Goodbye!" 0 0
		exit 0 
	fi
fi

# Display a list of departure cities
departure_city=$(city_menu "Select your departure city:" cities)

# Create another list and remove the selected city that way
# the departure and arrival can't be the same.
# Meets additional feature #1!

cities_filtered=()
for c in "${cities[@]}"
do 
    # If the current city != the city selected for departure, add it to the new list
	if [[ "$c" != "$departure_city" ]]
	then
        cities_filtered+=("$c")
	fi
done

# Display a list of destination cites
destination_city=$(city_menu "Select your destination city:" cities_filtered)

## Now we can get the departure and return dates

# Repeatedly display a calendar for the departure date in a while loop.
# If the selected date is valid, break out of the loop.
# Otherwise, keep going
while true
do
    if [[ $invalid_input -eq 1 ]] # If the failure flag is set (an invalid date was chosen),
	then
        dialog --keep-tite --title "Reservation Manager - Error" --msgbox "Invalid date: departure date must be on or after today's date!" 0 0 # dislay an error message.
	fi

    departure_date=$(dialog --keep-tite --title "Reservation Manager" --output-fd 1 --no-cancel --date-format "%m/%d/%Y" --calendar "Select your departure date:" 0 0)
	
	departure_month=$(echo "$departure_date" | awk -F'/' '{print $1}')
	departure_day=$(echo "$departure_date" | awk -F'/' '{print $2}')
	departure_year=$(echo "$departure_date" | awk -F'/' '{print $3}')
	
	now=$(date +%m/%d/%Y)
	now_month=$(echo "$now" | awk -F'/' '{print $1}')
	now_day=$(echo "$now" | awk -F'/' '{print $2}')
	now_year=$(echo "$now" | awk -F'/' '{print $3}')
	
	invalid_input=1 # Set the failure flag (if the selected date is invalid then this remains 1)
	# This nested formatting is messy but it makes date comparison logic work properly.
	# Another note: without "10#" before every number, they may be interpreted as
	# octal when they have a leading zero leading to improper comparisons.
	if [[ 10#$departure_year -lt 10#$now_year ]]
	then
		continue
	elif [[ 10#$departure_year -eq 10#$now_year ]]
	then
		if [[ 10#$departure_month -lt 10#$now_month ]]
		then
			continue
		elif [[ 10#$departure_month -eq 10#$now_month ]]
		then 
			if [[ 10#$departure_day -lt 10#$now_day ]]
			then
				continue
			fi
		fi
	fi

	invalid_input=0 # Reset the failure flag 

	break
done

# Same as above but with the return date.
while true
do	
    if [[ $invalid_input -eq 1 ]]
	then
        dialog --keep-tite --title "Reservation Manager - Error" --msgbox "Invalid date: return date must be on or after the set departure date of $departure_date!" 0 0
	fi

	return_date=$(dialog --keep-tite --title "Reservation Manager" --output-fd 1 --no-cancel --date-format "%m/%d/%Y" --calendar "Select your return date:" 0 0)
	
	return_month=$(echo "$return_date" | awk -F'/' '{print $1}')
	return_day=$(echo "$return_date" | awk -F'/' '{print $2}')
	return_year=$(echo "$return_date" | awk -F'/' '{print $3}')
	
	invalid_input=1
	
	if [[ 10#$return_year -lt 10#$departure_year ]]
	then
		continue
	elif [[ 10#$return_year -eq 10#$departure_year ]]
	then
		if [[ 10#$return_month -lt 10#$departure_month ]]
		then
			continue
		elif [[ 10#$return_month -eq 10#$departure_month ]]
		then 
			if [[ 10#$return_day -lt 10#$departure_day ]]
			then
				continue
			fi
		fi
	fi

	invalid_input=0 # Reset the failure flag 

	break
done

# Additional features #2 and #3 are now met!

# Displays an input box to read users number of bags
# This dialog does similar logic to the previous two
# but instead checks to see if the input is a valid number.
while true
do	
    if [[ $invalid_input -eq 1 ]] # If the failure flag is set (an invalid date was chosen),
	then
        dialog --keep-tite --title "Reservation Manager - Error" --msgbox "Invalid input: must be a valid number!" 0 0 # dislay an error message.
	fi

	bags=$(dialog --keep-tite --output-fd 1 --no-cancel --title "Reservation Manager" --inputbox "Enter your amount of checked bags:" 0 0)
	
	invalid_input=1 # Set the failure flag (if the selected date is invalid then this remains 1)
	
	if [[ $bags =~ ^[0-9]+$ ]]
	then
		invalid_input=0 # Reset the failure flag 
		break
	fi
done


## END OF DISPLAY MESSAGES

# Format to save reservation to txt file
reservation_info="$name|$bags|$departure_city|$destination_city|$departure_date|$return_date"

reservation_confirm reservation_info "Does this look correct?"

response=$?
if [[ $response -eq 0 ]] 
then
	dialog --keep-tite --title "Reservation Manager" --msgbox "Reservation saved. Goodbye!" 0 0


	# Check to see if there is a reservation that matches the name of the user
	if grep -q "^$name|" res.txt
	then
		# Removes the previous reservation
		sed -i "/^$name|/d" res.txt 
	fi

	# Write the reservation to the txt file
	echo "$reservation_info" >> res.txt
else
	dialog --keep-tite --title "Reservation Manager" --msgbox "Cancelled reservation. Goodbye!" 0 0
fi