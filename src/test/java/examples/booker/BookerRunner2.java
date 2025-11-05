package test.java.examples.booker;

import com.intuit.karate.junit5.Karate;

class BookerRunner2 {
    
    @Karate.Test
    Karate testBooker() {
        return Karate.run("booker2").relativeTo(getClass());
    }    

}
