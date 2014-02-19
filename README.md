# LinkedIn OAuth Tester
This is a quick test script that runs through the OAuth token creation flow for LinkedIn and validate that the newly created token works. This is meant to run periodically to determine patterns of failure in the flow.

## How it works
There are two parts that work together to test the flow: the test script and the callback service. 

### Test Script
The test script runs though a standard LinkedIn OAuth login flow for all of the accounts configured in the `accounts.yml`.  

For all of the test accounts that have been configured to run:

1. [LinkedIn 2](https://github.com/bobbrez/linkedin2) is used to generate the [Authorize URL](http://developer.linkedin.com/documents/authentication)
2. [Selenium Webdriver](https://code.google.com/p/selenium/) is used to automate the OAuth login
3. LinkedIn 2 is exchanges the passed code for a new Access Token

### Callback Service
This is a simple [Sinatra](http://www.sinatrarb.com) app that has one endpoint and essentially acts as an echo server. It just provides a soft spot for the OAuth redirect to land on.

## Dependencies

* Redis installed locally
* LinkedIn application credentials (see [LinkedIn Docs](http://developer.linkedin.com/documents/authentication) for more info)

## Setup

1. Make sure all dependencies are installed
2. Create a `.env` file at the root of the project with the LinkedIn application credentials. See below for an example.
3. Create an `accounts.yml` at the root of the project with all of the test accounts. See below for an example.

## Running

1. Run `bundle install` to install all necessary gems
2. Run `rake server` in a separate terminal to start the Callback Service. Note this will need to run in the foreground.
3. Run `rake test` after the server has started to run the test suite once

## CRON
To run the tests over time, setup a cron job to execute the test periodically. Each test account has a delay that will be respected so running the test every 2 minutes will not run all accounts, but will run those that are eligible.

`*/2 * * * * bash -lc "cd <your-path>; rake test"`

# Example Configs

## .env

```
LINKEDIN_APP_KEY=<YOUR LINKEDIN APP KEY>
LINKEDIN_SECRET=<YOUR LINKEDIN APP SECRET>
```

## accounts.yml
```
bob:
  username: bob@some-email.com
  password: apassword
  delay: 5

john:
  username: john@some-email.com
  password: anotherpassword
  delay: 30
```

Each listing is an account to test. `delay` is the number of minutes to wait before trying to test again.