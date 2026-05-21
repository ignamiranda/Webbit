class RuleSet {
  final Set<String> domainFilters;
  final Set<String> exceptionDomains;
  final Map<String, Set<String>> blockedPaths;
  final Map<String, Set<String>> exceptionPaths;
  final Set<String> hardBlockedDomains;
  final Set<String> fontExtensions;

  const RuleSet({
    this.domainFilters = const {},
    this.exceptionDomains = const {},
    this.blockedPaths = const {},
    this.exceptionPaths = const {},
    this.hardBlockedDomains = _defaultHardBlocked,
    this.fontExtensions = _defaultFontExtensions,
  });

  static const _defaultHardBlocked = <String>{
    'fonts.googleapis.com',
    'fonts.gstatic.com',
    'use.typekit.net',
    'pixel.redditmedia.com',
    'events.redditmedia.com',
    'out.reddit.com',
    'securepubads.g.doubleclick.net',
    'tpc.googlesyndication.com',
  };

  static const _defaultFontExtensions = <String>{
    '.woff2', '.woff', '.ttf', '.eot', '.otf',
  };

  RuleSet merge(RuleSet other) {
    return RuleSet(
      domainFilters: {...domainFilters, ...other.domainFilters},
      exceptionDomains: {...exceptionDomains, ...other.exceptionDomains},
      blockedPaths: {...blockedPaths, ...other.blockedPaths},
      exceptionPaths: {...exceptionPaths, ...other.exceptionPaths},
      hardBlockedDomains: {...hardBlockedDomains, ...other.hardBlockedDomains},
      fontExtensions: {...fontExtensions, ...other.fontExtensions},
    );
  }
}
