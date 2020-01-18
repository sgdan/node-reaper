package org.sgdan.nodereaper

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.SendChannel
import kotlinx.coroutines.channels.actor
import mu.KotlinLogging
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

private val log = KotlinLogging.logger {}
private val formatter: DateTimeFormatter =
        DateTimeFormatter.ofPattern("h:mma z")

sealed class Manager() {
    object Update : Manager()
    class UpdateNode(val id: String,
                     val status: NodeStatus) : Manager()

    class RemoveNode(val id: String) : Manager()
    class GetStatus(val job: CompletableDeferred<Status>) : Manager()
    class Extend(val id: String,
                 val job: CompletableDeferred<Status>) : Manager()
}

fun CoroutineScope.managerActor(ec2: Ec2) = actor<Manager> {
    val actors = HashMap<String, SendChannel<Node>>()
    val statuses = HashMap<String, NodeStatus>()

    fun status() = Status(statuses.values.toList().sortedBy { it.name })

    for (msg in channel) when (msg) {
        is Manager.GetStatus -> msg.job.complete(status())

        is Manager.Update -> try {
            // create actors for new nodes
            val live = ec2.getNodeIds()
            val existing = actors.keys.toSet()
            live.minus(existing).forEach {
                actors[it] = nodeActor(it, ec2, channel)
            }
        } catch (e: Exception) {
            log.error { "Unable to update nodes: ${e.message}" }
        }

        is Manager.UpdateNode -> {
            statuses[msg.id] = msg.status
        }

        is Manager.RemoveNode -> {
            actors.remove(msg.id)?.close()
            statuses.remove(msg.id)
            log.info("Node ${msg.id} was removed")
        }

        is Manager.Extend -> {
            val current = statuses[msg.id]
                    ?: throw Exception("Node with id ${msg.id} not found")
            statuses[msg.id] = current.copy(
                    canExtend = false,
                    remaining = "",
                    state = "extending...")
            actors[msg.id]?.send(Node.Extend)
            msg.job.complete(status())
        }
    }
}.also {
    tick(60, it, Manager.Update)
}

/**
 * Trigger specified message at regular intervals to an actor
 */
fun <T> tick(seconds: Long, channel: SendChannel<T>, msg: T) {
    GlobalScope.launch {
        while (!channel.isClosedForSend) {
            channel.send(msg)
            delay(seconds * 1000)
        }
    }
}
