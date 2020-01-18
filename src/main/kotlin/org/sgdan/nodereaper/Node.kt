package org.sgdan.nodereaper

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.SendChannel
import kotlinx.coroutines.channels.actor
import mu.KotlinLogging
import java.lang.System.currentTimeMillis
import java.time.ZoneId
import java.time.ZonedDateTime

private val log = KotlinLogging.logger {}

sealed class Node() {
    object Update : Node()
    object Extend : Node()
}

fun CoroutineScope.nodeActor(id: String,
                             ec2: Ec2,
                             manager: SendChannel<Manager>) = actor<Node> {
    lateinit var status: NodeStatus

    for (msg in channel) when (msg) {
        is Node.Update -> try {
            status = ec2.getNode(id)

            // stop or start if appropriate
            if (status.state == "running" && status.remaining.isEmpty()) {
                status = status.copy(state = "stopping...")
                ec2.stop(id)
                log.info { "Stopping $id" }
            } else if (status.state == "stopped" && status.remaining.isNotEmpty()) {
                status = status.copy(state = "starting...")
                ec2.start(id)
                log.info { "Starting $id" }
            }

            manager.send(Manager.UpdateNode(id, status))
        } catch (e: Exception) {
            log.error { "Unable to update node $id: ${e.message}" }
        }

        is Node.Extend -> try {
            ec2.start(id)
            ec2.setTimestamp(id)
            log.info { "Extending $id" }
        } catch (e: Exception) {
            log.error { "Unable to extend node $id: ${e.message}" }
        }
    }
}.also {
    tick(30, it, Node.Update)
}
