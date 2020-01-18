package org.sgdan.nodereaper

import io.micronaut.runtime.Micronaut

object Application {

    @JvmStatic
    fun main(args: Array<String>) {
        Micronaut.build()
                .packages("org.sgdan.nodereaper")
                .mainClass(Application.javaClass)
                .start()
    }
}
