# Restful-Booker API Test Suite

## Overview

This project contains automated API tests for the Restful-Booker platform using the Karate framework. The test suite validates all major functionalities of the booking system including authentication, CRUD operations, and various filtering capabilities.

## Project Structure

```bash
tareanum4/
├── src/
│   └── test/
│       └── java/
│           ├── karate-config.js
│           ├── logback-test.xml
│           └── examples/
│               ├── booker/
│               │   ├── booker.feature
│               │   ├── booker2.feature
│               │   ├── BookerRunner.java
│               │   └── BookerRunner2.java
│               └── users/
├── pom.xml
├── README.md
└── .gitignore
```

## Prerequisites

- Java 8 or higher
- Maven 3.6 or higher
- Internet connection (to access the Restful-Booker API)

## Installation

1. Clone this repository
2. Navigate to the project directory
3. Run `mvn clean install`

## Running Tests

To run all tests:

```bash
mvn test
```

To run specific test class:

```bash
mvn test -Dtest=BookerRunner
```

To run with alternate values

```bash
mvn test -Dkarate.env=staging
```

## Test Coverage

The test suite covers:

- Authentication & Authorization
- Create, Read, Update, and Delete operations for bookings
- Filtering bookings by various criteria
- Error scenarios and edge cases
- Schema validation
- Response validation

## Features Tested

1. **Authentication**
   - Token generation
   - Invalid credentials handling
   - Token validation

2. **Booking Operations**
   - Create new bookings
   - Retrieve booking details
   - Update existing bookings
   - Partial updates
   - Delete bookings

3. **Search & Filters**
   - Filter by name
   - Filter by date
   - Filter by date range

4. **Error Handling**
   - Invalid input validation
   - Non-existent resource handling
   - Authorization errors
   - Data validation errors

## Test Reports

After running the tests, HTML reports can be found at:

`target/karate-reports/karate-summary.html`

## API Documentation

The tested API documentation can be found at:
[Heroku APP](https://restful-booker.herokuapp.com/apidoc/index.html)

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request
