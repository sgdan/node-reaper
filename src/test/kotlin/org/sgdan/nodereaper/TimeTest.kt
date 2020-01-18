package org.sgdan.nodereaper

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class TimeTest {
    @Test
    fun calcRemaining() {
        val m = 60 * 1000
        val start = 1573261444114
        val stop = start + WINDOW * 60 * m // 8 hrs after start
        assertEquals("", remaining(0, stop))
        assertEquals("", remaining(stop - m + 1, start))
        assertEquals("1m", remaining(start, stop - m))
        assertEquals("5m", remaining(start, stop - 5 * m))
        assertEquals("10m", remaining(start, stop - 10 * m))
        assertEquals("1h 03m", remaining(start, stop - 63 * m))
        assertEquals("3h 59m", remaining(start, start + m))
        assertEquals("3h 59m", remaining(start, start + 1))
        assertEquals("", remaining(start, start))
        assertEquals("", remaining(start, start - 20 * m))
    }
}
