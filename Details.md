# Keyshare

Keyshare was developed as part of the LBAW course by MIEIC FEUP students :

* Luís Ramos, up201706253@fe.up.pt
* José Guerra, up201706421@fe.up.pt
* Martim Silva, up201705205@fe.up.pt
* Ruben Almeida, up201704618@fe.up.pt

## Project Description

Keyshare is an online global marketplace which specializes in the sale of gaming related digital products using redemption keys.

Keyshare is divided into two major parts:

* User side - Where we can buy, sell, review and report videogame keys
* Admin side - Where all information on the website can be updated / deleted but also insert new information

Keyshare was develped using Laravel framework using Bootstrap 4 as front-end design library and a Postgres Database architecture using PGAdmin as GUI interface with the database. \
**Note** - To get more info check the [wiki](https://github.com/motapinto/feup-LBAW/wiki)

## Iterations

This project is divided in 10 small iterations. The major checkpoints of the course were:
* Design Prototype
* Vertical Prototype
* Final Product

## Installation
The development was supported by docker technologies. You can run the project docker image with the following commands:
```
docker run -it -p 8000:80 -e DB_DATABASE="lbaw2043" -e DB_USERNAME="lbaw2043" -e DB_PASSWORD="AS810664" lbaw2043/lbaw2043
```

## Credentials

### User

In order to access Keyshare full functionalities, you need to be logged in you can register yourself or use the following credentials:
| Type          | Username         | Password       |
| ------------- | ---------------- | -------------- |
| basic account | ssn              | SergioNunes123 |
| banned user   | motapinto        | 123456789      |

### Administration

> Administration URL: /admin

| Username | Password       |
| -------- | -------------- |
| ssn      | SergioNunes123 |
