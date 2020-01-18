package org.sgdan.nodereaper

import mu.KotlinLogging
import software.amazon.awssdk.services.ec2.Ec2Client
import software.amazon.awssdk.services.ec2.model.DescribeInstancesRequest
import software.amazon.awssdk.services.ec2.model.Filter
import software.amazon.awssdk.services.ec2.model.Instance
import software.amazon.awssdk.services.ec2.model.Tag
import java.lang.System.currentTimeMillis

const val TAG_ENABLE = "reaper-enable"
const val TAG_TIMESTAMP = "reaper-timestamp"

private val log = KotlinLogging.logger {}

/**
 * Wraps read and write operations on the kubernetes cluster
 */
class Ec2() {
    private val client = Ec2Client.create()

    /**
     * @return a list containing IDs of all the nodes with reaper enabled
     */
    fun getNodeIds(): List<String> = try {
        val filter = Filter.builder().name("tag:${TAG_ENABLE}").values("true").build()
        val req = DescribeInstancesRequest.builder().filters(filter).build()
        val res = client.describeInstances(req)
        res.reservations().flatMap { reservation ->
            reservation.instances().map { it.instanceId() }
        }.toList()
    } catch (e: Exception) {
        log.error { "Unable to get nodes: ${e.message}" }
        emptyList<String>()
    }

    private fun getTimestamp(i: Instance): Long = try {
        i.tags().find { it.key() == TAG_TIMESTAMP }
                ?.value()?.toLong() ?: 0
    } catch (e: Exception) {
        log.warn { "Invalid instance timestamp: ${e.message}" }
        0
    }

    fun getNode(id: String): NodeStatus {
        val filter = Filter.builder().name("instance-id").values(id).build()
        val instance = client.describeInstances { it.filters(filter) }
                ?.reservations()?.get(0)
                ?.instances()?.get(0) ?: throw Exception("No instance with id $id")
        val now = currentTimeMillis()
        val lastExtend: Long = getTimestamp(instance)
        return NodeStatus(
                name = instance.tags()?.find { it.key() == "Name" }?.value() ?: "",
                id = id,
                ip = instance.privateIpAddress(),
                instanceType = instance.instanceType().toString(),
                canExtend = canExtend(lastExtend, now),
                remaining = remaining(lastExtend, now),
                state = instance.state().nameAsString())
    }

    fun start(id: String) = try {
        client.startInstances { it.instanceIds(id) }
    } catch (e: Exception) {
        log.error { "Unable to start node $id: ${e.message}" }
    }

    fun stop(id: String) = try {
        client.stopInstances { it.instanceIds(id) }
    } catch (e: Exception) {
        log.error { "Unable to stop node $id: ${e.message}" }
    }

    private fun setTag(id: String, name: String, value: String) = try {
        client.createTags {
            val tag = Tag.builder().key(name).value(value).build()
            it.resources(id).tags(tag)
        }
    } catch (e: Exception) {
        log.error { "Unable to set tag $name:$value for node $id: ${e.message}" }
    }

    fun setTimestamp(id: String) {
        setTag(id, TAG_TIMESTAMP, currentTimeMillis().toString())
    }
}
