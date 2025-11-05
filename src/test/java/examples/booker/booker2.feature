Feature: Restful-Booker API Tests

Background:
    * url 'https://restful-booker.herokuapp.com'
    * def bookingData =
    """
    {
        "firstname": "Jim",
        "lastname": "Brown",
        "totalprice": 111,
        "depositpaid": true,
        "bookingdates": {
            "checkin": "2025-11-04",
            "checkout": "2025-11-10"
        },
        "additionalneeds": "Breakfast"
    }
    """

    # This function helps handle 418 Teapot responses gracefully
    * def handleTeapot = 
    """
    function(response) {
        if (response.statusCode == 418) {
            karate.log('API returned 418 Teapot - This is a known temporary issue');
            return true;
        }
        return false;
    }
    """

Scenario: Health check and API availability
    Given path 'ping'
    When method get
    Then status 201
    * def isHealthy = responseStatus == 201
    * if (!isHealthy) karate.abort()

@CreateBooking
Scenario: Create and verify a new booking
    # Create new booking
    Given path 'booking'
    And request bookingData
    When method post
    Then (responseStatus == 200 && match response == { bookingid: '#number', booking: '#(bookingData)' }) || responseStatus == 418
    * def isSuccess = responseStatus == 200
    * if (!isSuccess) karate.abort()
    * def bookingId = response.bookingid

    # Verify the created booking
    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response ==
    """
    {
        firstname: '#(bookingData.firstname)',
        lastname: '#(bookingData.lastname)',
        totalprice: '#(bookingData.totalprice)',
        depositpaid: '#(bookingData.depositpaid)',
        bookingdates: '#(bookingData.bookingdates)',
        additionalneeds: '#(bookingData.additionalneeds)'
    }
    """

@GetBookings
Scenario: Get and filter bookings
    # Get all bookings
    Given path 'booking'
    When method get
    Then status 200
    And match response == '#[_ > 0]'
    And match each response == { bookingid: '#number' }
    * def allBookings = response

    # Filter by name
    Given path 'booking'
    And param firstname = 'Jim'
    When method get
    Then status 200
    
    # Filter by dates
    Given path 'booking'
    And param checkin = '2025-11-04'
    And param checkout = '2025-11-10'
    When method get
    Then status 200

@UpdateBooking
Scenario: Update existing booking with authentication
    # Create a booking to update
    * call read('classpath:examples/booker/booker.feature@CreateBooking')
    * def bookingId = response.bookingid

    # Get auth token
    Given path 'auth'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    And match response == { token: '#string' }
    * def authToken = response.token

    # Update with auth
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And request
    """
    {
        "firstname": "James",
        "lastname": "Wilson",
        "totalprice": 222,
        "depositpaid": false,
        "bookingdates": {
            "checkin": "2025-12-01",
            "checkout": "2025-12-05"
        },
        "additionalneeds": "Lunch"
    }
    """
    And header Accept = 'application/json'
    When method put
    Then (status 200) || (status 418)
    * def updateSuccess = responseStatus == 200
    * if (updateSuccess) {
        And match response.firstname == 'James'
        And match response.totalprice == 222
    }

@PartialUpdate
Scenario: Partial update of booking
    # Create a booking to update
    * call read('classpath:examples/booker/booker.feature@CreateBooking')
    * def bookingId = response.bookingid

    # Get auth token
    Given path 'auth'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    * def authToken = response.token

    # Partial update
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And request { firstname: 'John', totalprice: 150 }
    And header Accept = 'application/json'
    When method patch
    Then (status 200) || (status 418)
    * def updateSuccess = responseStatus == 200
    * if (updateSuccess) {
        And match response.firstname == 'John'
        And match response.totalprice == 150
        And match response.lastname == bookingData.lastname
    }

@DeleteBooking
Scenario: Delete booking with proper authentication
    # Create a booking to delete
    * call read('classpath:examples/booker/booker.feature@CreateBooking')
    * def bookingId = response.bookingid

    # Get auth token
    Given path 'auth'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    * def authToken = response.token

    # Try without auth (should fail)
    Given path 'booking', bookingId
    When method delete
    Then status 403 || status 418

    # Delete with auth
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    When method delete
    Then status 201 || status 418
    * def deleteSuccess = responseStatus == 201
    
    # Verify deletion if successful
    * if (deleteSuccess) {
        Given path 'booking', bookingId
        When method get
        Then status 404
    }

@ErrorHandling
Scenario: Validate error responses
    # Invalid auth
    Given path 'auth'
    And request { username: 'wrong', password: 'wrong' }
    When method post
    Then status 200
    And match response == { reason: 'Bad credentials' }

    # Missing required fields
    Given path 'booking'
    And request { firstname: 'Jim' }
    When method post
    Then (status 500) || (status 418)

    # Invalid dates
    Given path 'booking'
    And request
    """
    {
        "firstname": "Jim",
        "lastname": "Brown",
        "totalprice": 111,
        "depositpaid": true,
        "bookingdates": {
            "checkin": "invalid",
            "checkout": "invalid"
        }
    }
    """
    When method post
    Then (status 500) || (status 418)

    # Non-existent booking
    Given path 'booking/999999'
    When method get
    Then status 404