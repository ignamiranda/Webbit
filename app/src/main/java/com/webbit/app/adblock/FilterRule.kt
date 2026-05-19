package com.webbit.app.adblock

enum class RuleType { BLOCK, EXCEPTION }

data class FilterRule(
    val type: RuleType,
    val domain: String?,
    val patternRegex: Regex?,
    val resourceTypes: Set<String>?,
)

object FilterParser {
    private val RESOURCE_TYPES = setOf(
        "script", "image", "stylesheet", "object", "font", "media",
        "xmlhttprequest", "subdocument", "ping", "websocket", "other"
    )

    fun parseLine(line: String): FilterRule? {
        val trimmed = line.trim()
        if (trimmed.isEmpty() || trimmed[0] == '!' || trimmed[0] == '#') return null

        var remaining = trimmed
        val type: RuleType

        if (remaining.startsWith("@@")) {
            type = RuleType.EXCEPTION
            remaining = remaining.removePrefix("@@")
        } else {
            type = RuleType.BLOCK
        }

        var resourceTypes: Set<String>? = null
        val dollarIndex = remaining.indexOf('$')
        if (dollarIndex >= 0) {
            val options = remaining.substring(dollarIndex + 1).split(',')
            remaining = remaining.substring(0, dollarIndex)
            val types = mutableSetOf<String>()
            for (opt in options) {
                if ((opt.startsWith("domain=") || opt.startsWith("~") || opt == "third-party")) {
                    continue
                }
                if (opt in RESOURCE_TYPES) types.add(opt)
            }
            if (types.isNotEmpty()) resourceTypes = types
        }

        val clean = remaining.trimEnd('^', '|')

        val domain: String?
        val patternRegex: Regex?

        if (clean.startsWith("||")) {
            val afterDomain = clean.removePrefix("||")
            val slashIndex = afterDomain.indexOf('/')
            if (slashIndex >= 0) {
                domain = afterDomain.substring(0, slashIndex)
                val path = afterDomain.substring(slashIndex)
                patternRegex = if (path.isEmpty() || path == "/") null else globToRegex(path)
            } else {
                domain = afterDomain
                patternRegex = null
            }
        } else if (clean.startsWith("|")) {
            domain = null
            patternRegex = globToRegex(clean)
        } else if (clean.startsWith("//")) {
            return null
        } else {
            domain = null
            patternRegex = if (clean.isNotEmpty()) globToRegex(clean) else null
        }

        return FilterRule(
            type = type,
            domain = domain,
            patternRegex = patternRegex,
            resourceTypes = resourceTypes,
        )
    }

    internal fun globToRegex(pattern: String): Regex {
        val sb = StringBuilder()
        var i = 0
        while (i < pattern.length) {
            val ch = pattern[i]
            when (ch) {
                '*' -> sb.append(".*")
                '?' -> sb.append('.')
                '^' -> sb.append("(?:[^a-zA-Z0-9_]|$)")
                else -> {
                    if (ch in ".*+?^${}()|[]\\") sb.append('\\')
                    sb.append(ch)
                }
            }
            i++
        }
        return Regex(sb.toString(), RegexOption.IGNORE_CASE)
    }
}
