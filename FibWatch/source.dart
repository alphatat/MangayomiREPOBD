import '../../../../../model/source.dart';

Source get fibwatchSource => _fibwatchSource;
const _fibwatchVersion = "0.0.1";
const _fibwatchSourceCodeUrl =
    "https://raw.githubusercontent.com/alphatat/MangayomiREPOBD/refs/heads/main/FibWatch/fibwatch.dart";
Source _fibwatchSource = Source(
  name: "FibWatch",
  baseUrl: "https://fibwatch.art",
  lang: "bn",
  typeSource: "single",
  iconUrl:
      "https://raw.githubusercontent.com/alphatat/MangayomiREPOBD/refs/heads/main/FibWatch/icon.png",
  sourceCodeUrl: _fibwatchSourceCodeUrl,
  version: _fibwatchVersion,
  itemType: ItemType.anime,
);
