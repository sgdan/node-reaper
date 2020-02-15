package org.sgdan.nodereaper

import io.micronaut.context.annotation.Parallel
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.GlobalScope
import javax.inject.Singleton

@Singleton
@Parallel // Don't wait until the first request before starting up!
class Backend {
    private val ec2: Ec2 = Ec2()
    private val manager =
            GlobalScope.run { managerActor(ec2) }

    suspend fun getStatus(): Status =
            CompletableDeferred<Status>()
                    .also { manager.send(Manager.GetStatus(it)) }
                    .await()

    suspend fun extend(id: String): Status =
            CompletableDeferred<Status>()
                    .also { manager.send(Manager.Extend(id, it)) }
                    .await()
}
