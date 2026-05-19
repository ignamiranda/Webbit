package com.webbit.app.adblock

import android.net.Uri

class AdBlockerEngine {

    private val domainBlockRules = mutableMapOf<String, MutableList<FilterRule>>()
    private val domainExceptionRules = mutableMapOf<String, MutableList<FilterRule>>()
    private val genericBlockRules = mutableListOf<FilterRule>()
    private val genericExceptionRules = mutableListOf<FilterRule>()

    val ruleCount: Int
        get() = domainBlockRules.values.sumOf { it.size } +
                domainExceptionRules.values.sumOf { it.size } +
                genericBlockRules.size +
                genericExceptionRules.size

    fun loadRules(rules: List<FilterRule>) {
        domainBlockRules.clear()
        domainExceptionRules.clear()
        genericBlockRules.clear()
        genericExceptionRules.clear()

        for (rule in rules) {
            val domain = rule.domain
            if (domain == null) {
                if (rule.type == RuleType.EXCEPTION) {
                    genericExceptionRules.add(rule)
                } else {
                    genericBlockRules.add(rule)
                }
            } else {
                val map = if (rule.type == RuleType.EXCEPTION) domainExceptionRules else domainBlockRules
                map.getOrPut(domain) { mutableListOf() }.add(rule)
            }
        }
    }

    fun clear() {
        domainBlockRules.clear()
        domainExceptionRules.clear()
        genericBlockRules.clear()
        genericExceptionRules.clear()
    }

    fun shouldBlock(url: String, resourceType: String?): Boolean {
        if (url.startsWith("file:") || url.startsWith("data:") || url.startsWith("blob:")) return false

        val uri = Uri.parse(url)
        val host = uri.host ?: return false
        val fullUrl = uri.toString()

        val domains = generateDomainCandidates(host)

        var matched = false

        for (d in domains) {
            for (rule in domainBlockRules[d].orEmpty()) {
                if (matches(rule, host, fullUrl, resourceType)) {
                    matched = true
                }
            }
        }
        for (rule in genericBlockRules) {
            if (matches(rule, host, fullUrl, resourceType)) {
                matched = true
            }
        }

        if (!matched) return false

        for (d in domains) {
            for (rule in domainExceptionRules[d].orEmpty()) {
                if (matches(rule, host, fullUrl, resourceType)) {
                    return false
                }
            }
        }
        for (rule in genericExceptionRules) {
            if (matches(rule, host, fullUrl, resourceType)) {
                return false
            }
        }

        return true
    }

    private fun matches(
        rule: FilterRule,
        host: String,
        fullUrl: String,
        resourceType: String?,
    ): Boolean {
        if (rule.resourceTypes != null && resourceType != null && resourceType !in rule.resourceTypes) {
            return false
        }

        if (rule.patternRegex != null) {
            if (!rule.patternRegex.containsMatchIn(fullUrl)) return false
        }

        return true
    }

    private fun generateDomainCandidates(host: String): List<String> {
        val parts = host.split('.')
        return parts.indices.map { parts.drop(it).joinToString(".") }
    }
}
