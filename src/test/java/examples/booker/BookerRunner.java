package examples.booker;

import com.intuit.karate.junit5.Karate;

class BookerRunner {
    
    @Karate.Test
    Karate testBooker() {
        return Karate.run("booker").relativeTo(getClass());
    }    

}