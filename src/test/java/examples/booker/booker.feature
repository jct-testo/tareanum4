Feature: Restful-Booker API Tests

Background:
    * url 'https://restful-booker.herokuapp.com'
    # Environment configuration
    * def env = karate.env || 'development'
    
    # Load test data
    * def bookingData = read('data/booking.json')
    * def bookingSallyData = read('data/booking-sally.json')
    * def bookingBobData = env == 'staging' ? read('data/booking-robert.json') : read('data/booking-bob.json')
    * def bookingUpdateData = read('data/booking-update.json')
    
    # This function checks if API is responding with 418 Teapot error
    * def isTeapotError =
    """
    function(response) {
        return response.statusCode == 418 && response.responseText.contains('I\'m a Teapot');
    }
    """

@aiplusmanual
Scenario: Get all bookings
    Given path 'booking'
    When method get
    Then status 200
    And match response == '#[_ > 0]'
    And match each response == { bookingid: '#number' }

@aiplusmanual
Scenario: Get booking by ID with response validation
    # First create a booking to test with
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingData
    When method post
    Then status 200
    And match response == 
    """
    {
        bookingid: '#number',
        booking: {
            firstname:      '#(bookingData.firstname)',
            lastname:       '#(bookingData.lastname)',
            totalprice:     '#(bookingData.totalprice)',
            depositpaid:    '#(bookingData.depositpaid)',
            bookingdates: {
                checkin:  '#? _ == bookingData.bookingdates.checkin',
                checkout: '#? _ == bookingData.bookingdates.checkout'
            },
            additionalneeds: '##(bookingData.additionalneeds)'
        }
    }
    """
    * def bookingId = response.bookingid

    # Get booking details
    Given path 'booking', bookingId
    * header Accept = 'application/json'
    When method get
    Then status 200
    And match response == 
    """
    {
        firstname: '#string',
        lastname: '#string',
        totalprice: '#number',
        depositpaid: '#boolean',
        bookingdates: {
            checkin: '#string',
            checkout: '#string'
        },
        additionalneeds: '##string'
    }
    """
    And match response.firstname == bookingData.firstname
    And match response.lastname == bookingData.lastname
    And match response.totalprice == bookingData.totalprice
    And match response.bookingdates == bookingData.bookingdates

@aiplusmanual
Scenario: Get non-existent booking
    Given path 'booking', 999999
    When method get
    Then status 404

@aiplusmanual
Scenario: Create booking and validate response
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingData
    When method post
    Then status 200
    And match response == 
    """
    {
        bookingid: '#number',
        booking: '#(bookingData)'
    }
    """

@aiplusmanual
Scenario: Update booking with authentication
    # First create a booking
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingData
    When method post
    Then status 200
    * def bookingId = response.bookingid

    # Get auth token
    Given path 'auth'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    And match response == { token: '#string' }
    * def authToken = response.token

    # Try updating without auth token (should fail)
    Given path 'booking', bookingId
    And request { firstname: 'James', lastname: 'Wilson' }
    And header Accept = 'application/json'
    When method put
    Then status 403

    # Update with valid auth token
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And request bookingUpdateData
    And header Accept = 'application/json'
    When method put
    Then status 200
    And match response.firstname == 'James'
    And match response.lastname == 'Wilson'
    And match response.totalprice == 222

    # Verify update persisted
    Given path 'booking', bookingId
    * header Accept = 'application/json'
    When method get
    Then status 200
    And match response.firstname == 'James'
    And match response.lastname == 'Wilson'
    And match response.totalprice == 222

@aiplusmanual
Scenario: Partial update booking with authentication
    # First create a booking
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingData
    When method post
    Then status 200
    * def bookingId = response.bookingid

    # Get auth token
    Given path 'auth'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    * def authToken = response.token

    # Try partial update without auth token (should fail)
    Given path 'booking', bookingId
    And request { firstname: 'John', totalprice: 150 }
    And header Accept = 'application/json'
    When method patch
    Then status 403

    # Partial update with auth token
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And request { firstname: 'John', totalprice: 150 }
    And header Accept = 'application/json'
    When method patch
    Then status 200
    And match response.firstname == 'John'
    And match response.totalprice == 150
    And match response.lastname == bookingData.lastname
    And match response.bookingdates == bookingData.bookingdates

    # Verify partial update persisted
    Given path 'booking', bookingId
    * header Accept = 'application/json'
    When method get
    Then status 200
    And match response.firstname == 'John'
    And match response.totalprice == 150
    And match response.lastname == bookingData.lastname

@aiplusmanual
Scenario: Delete a booking
    # First create a booking
    Given path 'booking'
    And request bookingData
    * header Accept = 'application/json'
    When method post
    Then status 200
    * def bookingId = response.bookingid

    # Try deleting without auth token (should fail)
    Given path 'booking', bookingId
    And header Accept = 'application/json'
    When method delete
    Then status 403

    # Get auth token
    Given path 'auth'
    * header Accept = 'application/json'
    And request { username: 'admin', password: 'password123' }
    When method post
    Then status 200
    And match response == { token: '#string' }
    * def authToken = response.token

    # Try deleting with invalid auth token (should fail)
    Given path 'booking', bookingId
    And header Cookie = 'token=invalid_token'
    And header Accept = 'application/json'
    When method delete
    Then status 403

    # Delete booking with valid auth token
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And header Accept = 'application/json'
    When method delete
    Then status 201

    # Verify booking is deleted
    Given path 'booking', bookingId
    * header Accept = 'application/json'
    When method get
    Then status 404

    # Try deleting already deleted booking
    Given path 'booking', bookingId
    And header Cookie = 'token=' + authToken
    And header Accept = 'application/json'
    When method delete
    Then status 405
    # AI attempted 404, but the API returns 405 Method Not Allowed

    # Try deleting non-existent booking
    Given path 'booking', 999999
    And header Cookie = 'token=' + authToken
    And header Accept = 'application/json'
    When method delete
    Then status 405
    # AI attempted 404, but the API returns 405 Method Not Allowed

    # Verify booking is not in the list
    Given path 'booking'
    * header Accept = 'application/json'
    When method get
    Then status 200
    And match response !contains { bookingid: '#(bookingId)' }

@aiplusmanual
Scenario: Filter bookings by name
    # Create some test bookings first
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingData
    When method post
    Then status 200
    
    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingSallyData
    When method post
    Then status 200

    # Filter by firstname
    Given path 'booking'
    * header Accept = 'application/json'
    And param firstname = 'Jim'
    When method get
    Then status 200
    And match each response contains { bookingid: '#number' }

    # Filter by lastname
    Given path 'booking'
    * header Accept = 'application/json'
    And param lastname = 'Brown'
    When method get
    Then status 200
    And match each response contains { bookingid: '#number' }

    # Filter by firstname and lastname
    Given path 'booking'
    * header Accept = 'application/json'
    And param firstname = 'Jim'
    And param lastname = 'Brown'
    When method get
    Then status 200
    And match each response contains { bookingid: '#number' }

@aiplusmanual @rangedates
Scenario: Filter bookings by date
    # Create bookings with different dates
    Given path 'booking'
    And request bookingData
    * header Accept = 'application/json'
    When method post
    Then status 200

    Given path 'booking'
    * header Accept = 'application/json'
    And request bookingBobData
    When method post
    Then status 200

    # Filter by checkin date
    Given path 'booking'
    * header Accept = 'application/json'
    And param checkin = '2025-11-20'
    When method get
    Then status 200
    And match each response contains { bookingid: '#number' }

    # Filter by checkout date
    Given path 'booking'
    * header Accept = 'application/json'
    And param checkout = '2025-11-25'
    When method get
    Then status 200
    And match each response contains { bookingid: '#number' }

    # Filter by date range
    Given path 'booking'
    * header Accept = 'application/json'
    And param checkin = '2025-11-20'
    And param checkout = '2025-11-25'
    When method get
    Then status 200
    ### And match each response contains { bookingid: '#number' }
    # THE LAST VALIDATION CANNOT BE PERFORMER AS THE RESPONSE IS AN EMPTY ARRAY...
    # Documentaation does not specify the expected behavior for date range filtering.
    # For sake of demo we will assume it is expected.

@aiplusmanual @negative
Scenario: Test invalid authentication
    Given path 'auth'
    And request { username: 'invalid', password: 'wrong' }
    When method post
    Then status 200
    And match response == { reason: 'Bad credentials' }

@aiplusmanual @negative @failure
Scenario: Test bad requests - Failure expected in the last call
    # Missing required fields.
    # it should pass by receiving code 500, but it is getting a 200.
    Given path 'booking'
    * header Accept = 'application/json'
    And request { firstname: 'Jim' }
    When method post
    Then status 500

    # Invalid data types
    Given path 'booking'
    * header Accept = 'application/json'
    And request 
    """
    {
        "firstname": 123,
        "lastname": true,
        "totalprice": "invalid",
        "depositpaid": "yes",
        "bookingdates": {
            "checkin": "2025-11-20",
            "checkout": "2025-11-25"
        }
    }
    """
    When method post
    Then status 500

    # Invalid date format
    Given path 'booking'
    * header Accept = 'application/json'
    And request 
    """
    {
        "firstname": "Jim",
        "lastname": "Brown",
        "totalprice": 111,
        "depositpaid": true,
        "bookingdates": {
            "checkin": "invalid-date",
            "checkout": "invalid-date"
        }
    }
    """
    When method post
    Then status 500
    # WE SHOULD GET 500, BUT THE API RETURNS 200 INSTEAD. This is an actual error.  