package org.sgdan.nodereaper

import io.micronaut.http.annotation.Body
import io.micronaut.http.annotation.Controller
import io.micronaut.http.annotation.Get
import io.micronaut.http.annotation.Post
import kotlinx.coroutines.runBlocking

data class ExtendRequest(val id: String)

@Controller("/")
class Controller(private val backend: Backend) {

    @Get("/reaper/status")
    fun status(): Status = runBlocking { backend.getStatus() }

    @Post("/reaper/extend")
    fun extend(@Body req: ExtendRequest) = runBlocking {
        backend.extend(req.id)
    }
}
