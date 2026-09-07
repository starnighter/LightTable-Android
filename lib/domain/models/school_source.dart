final class SchoolSource {
  const SchoolSource({
    required this.shortName,
    required this.name,
    required this.portalUrl,
    required this.scriptAsset,
  });

  final String shortName;
  final String name;
  final String portalUrl;
  final String scriptAsset;
}

abstract final class SchoolSources {
  static const csu = SchoolSource(
    shortName: 'Csu',
    name: '中南大学',
    portalUrl: 'http://csujwc.its.csu.edu.cn/sso.jsp',
    scriptAsset: 'assets/scripts/CsuExtractScript.js',
  );

  static const supported = <SchoolSource>[csu];
}
