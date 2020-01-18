package org.sgdan.nodereaper

const val WINDOW = 4 // Four hour up-time window
const val WINDOW_SECONDS = WINDOW * 60 * 60

/**
 * Can only extend once at least an hour has elapsed since last extend
 */
fun canExtend(lastStarted: Long, now: Long) =
        remainingSeconds(lastStarted, now) < WINDOW_SECONDS - 60 * 60

fun remaining(lastStarted: Long, now: Long) =
        remainingTime(remainingSeconds(lastStarted, now))

private fun remainingSeconds(lastStarted: Long, now: Long) =
        java.lang.Long.max(lastStarted + WINDOW_SECONDS * 1000 - now, 0) / 1000

private fun remainingTime(remaining: Long): String {
    val m = remaining / 60
    val h = (m / 60) % WINDOW

    return when {
        m <= 0 || m >= WINDOW * 60 -> ""
        h > 0 -> "${h}h %02dm".format(m % 60)
        else -> "${m % 60}m"
    }
}
