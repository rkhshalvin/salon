#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"


echo -e "\n ~~~~ MY Salon ~~~~\n"

MAIN_MENU(){

if [[ $1 ]]
then
  echo -e "\n$1"
fi

echo -e "\nWelcome to My Salon, how can I help you?"
echo -e "\n1. Make an appointment, \n2. Cancel an Appointment, \n3. Exit"
read MAIN_MENU_SELECTION


case $MAIN_MENU_SELECTION in
  1) BOOK_MENU ;;
  2) CANCEL_MENU ;;
  3) EXIT ;;
  *) MAIN_MENU "Please enter a valid option." ;;
esac
}


BOOK_MENU(){

  if [[ $1 ]]
then
  echo -e "\n$1"
fi
#get available services

AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services")

#list available services
echo -e "\nHere are the services we have available:"
echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
do 
  echo "$SERVICE_ID) $NAME"
done
#ask for service to book
echo -e "\nWhich service would you like?"
read SERVICE_ID_SELECTED

 if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
      then 
      MAIN_MENU "That is not a valid service."
    else
    SERVICE_TO_BOOK=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      if [[ -z $SERVICE_TO_BOOK ]]
        then
        MAIN_MENU "That service is not available."
      else 
      #get customer info
      echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE
        CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
        #if customer doesn't exist
        if [[ -z $CUSTOMER_NAME ]]
          then
          # get new customer name
           echo -e "\nI don't have a record for that phone number, what's your name?"
            read CUSTOMER_NAME
            # insert new customer
            INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
            echo -e "\nWhat time would you like your $SERVICE_TO_BOOK, $CUSTOMER_NAME?"
              read SERVICE_TIME
              
            else 
              echo -e "\nWhat time would you like your $SERVICE_TO_BOOK, $CUSTOMER_NAME?"
              read SERVICE_TIME
              
          fi
  # get customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # insert bike rental
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

 
  #send to main menu
  MAIN_MENU "I have put you down for a $SERVICE_TO_BOOK at $SERVICE_TIME,$CUSTOMER_NAME."

      fi

  fi


}

CANCEL_MENU(){
#get customer info
echo -e "\nWhat's your phone number?"
read CUSTOMER_PHONE
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

#if not found
if [[ -z $CUSTOMER_ID ]]
  then
    #send to main menu
    MAIN_MENU "I could not find a record for that phone number."
  else
    #get customer's rentals
    #APPOINTMENTS=$($PSQL "SELECT services.service_id, services.name FROM services FULL JOIN appointments using(service_id) FULL JOIN customers using(customer_id) where phone ='$CUSTOMER_PHONE' ORDER BY service_id;")
    #APPOINTMENTS=$($PSQL "SELECT a.service_id, s.name FROM appointments a JOIN services s USING(service_id) JOIN customers c USING(customer_id) WHERE c.phone = '$CUSTOMER_PHONE' ORDER BY a.service_id;")
    APPOINTMENTS=$($PSQL "SELECT services.service_id, services.name, appointments.time FROM services INNER JOIN appointments USING(service_id) INNER JOIN customers USING(customer_id) WHERE phone = '$CUSTOMER_PHONE' ORDER BY appointments.service_id;")
    #if no rentals
    if [[ -z $APPOINTMENTS ]]
    then
    #send to main menu
    MAIN_MENU "You do not have any services booked."
    else
    #display rented bikes
    echo -e "\nHere are the services booked for you:"
    echo "$APPOINTMENTS" | while read SERVICE_ID BAR NAME BAR TIME
        do 
    echo  "$SERVICE_ID) $NAME - $TIME"
    done
    #ask for service to cancel
    echo -e "\nWhich service would you like to cancel?"
    read SERVICE_TO_CANCEL
    #if not a number
    if [[ ! $SERVICE_TO_CANCEL =~ ^[0-9]+$ ]]
    then
  # send to main menu
    MAIN_MENU "That is not a valid service."
    else
    #check if service is booked
    APPOINTMENT_ID=$($PSQL "SELECT appointment_id FROM appointments INNER JOIN customers USING(customer_id) WHERE phone = '$CUSTOMER_PHONE' AND service_id = $SERVICE_TO_CANCEL")
    #if input not rented
        if [[ -z $APPOINTMENT_ID ]]
        then
           #send to main menu
           MAIN_MENU "You do not have that service booked."
         else 
         #update date_returned
         #CANCEL_RESULT=$($PSQL "DELETE FROM appointments set time = NULL WHERE appointment_id = $APPOINTMENT_ID")
         CANCEL_RESULT=$($PSQL "DELETE FROM appointments WHERE appointment_id = $APPOINTMENT_ID")

         
         #send to main menu
         MAIN_MENU "Thank you for updating your appointment."

        fi



    fi


    
    fi
fi
}

EXIT(){
echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU