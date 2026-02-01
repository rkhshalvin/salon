#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n ~~~~ MY Salon ~~~~\n"

BOOK_SERVICE(){

  # get available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # display services
  echo -e "\nHow can I help you today?\n"
  echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
  do
    echo "$SERVICE_ID) $NAME"
    #echo "$SERVICE_ID) $(echo $NAME | xargs)"
  done

  # ask for service
  echo -e "\nEnter a service_id:"
  read SERVICE_ID_SELECTED

  # validate service
  SELECTED_SERVICE=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  if [[ -z $SELECTED_SERVICE ]]
  then
    BOOK_SERVICE
  else
    # get phone number
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    # check if customer exists
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    if [[ -z $CUSTOMER_NAME ]]
    then
      # new customer - get name
      echo -e "\nWhat's your name?"
      read CUSTOMER_NAME

      # insert new customer
      $PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')" > /dev/null
    fi

    # get time
    echo -e "\nWhat time would you like?"
    read SERVICE_TIME

    # get customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    # trim whitespace
    CUSTOMER_NAME=$(echo $CUSTOMER_NAME | xargs)
    SELECTED_SERVICE=$(echo $SELECTED_SERVICE | xargs)

    # insert appointment
    $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')" > /dev/null

    # confirmation message
    echo -e "\nI have put you down for a $SELECTED_SERVICE at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

BOOK_SERVICE