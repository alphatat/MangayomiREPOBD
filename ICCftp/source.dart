import '../../../../../model/source.dart';

Source get iccftpSource => _iccftpSource;
const _iccftpVersion = "0.0.1";
const _iccftpSourceCodeUrl =
    "https://raw.githubusercontent.com/alphatat/MangayomiREPOBD/refs/heads/main/ICCftp/iccftp.dart";
Source _iccftpSource = Source(
  name: "ICCFTP",
  baseUrl: "http://10.16.100.244/",
  lang: "bn",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/alphatat/MangayomiREPOBD/refs/heads/main/ICCftp/icon.svg",
  sourceCodeUrl: _iccftpSourceCodeUrl,
  version: _iccftpVersion,
  itemType: ItemType.anime,
);
