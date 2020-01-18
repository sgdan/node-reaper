package org.sgdan.nodereaper

/**
 * A read-only snapshot of the relevant data from the kubernetes
 * cluster describing the namespaces we're interested in.
 */
data class Status(val nodes: List<NodeStatus> = emptyList())

data class NodeStatus(
        val name: String,
        val id: String,
        val ip: String,
        val instanceType: String,
        val canExtend: Boolean,
        val remaining: String,
        val state: String)
