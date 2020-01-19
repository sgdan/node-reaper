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

            // remove actors for nodes not in the list
            existing.minus(live).forEach {
                actors.remove(it)?.close()
                statuses.remove(it)
                log.info("Node $it was removed")
            }
        } catch (e: Exception) {
            log.error { "Unable to update nodes: ${e.message}" }
        }

        is Manager.UpdateNode -> {
            statuses[msg.id] = msg.status
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
    tick(30, it, Manager.Update)
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
