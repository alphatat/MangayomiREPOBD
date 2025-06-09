import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class FibWatch extends MProvider {
  FibWatch({required this.source});

  MSource source;

  final Client client = Client();

  @override
  bool get supportsLatest => true;

  @override
  String get baseUrl => getPreferenceValue(source.id, "pref_domain_new");

  @override 
  Future<MPages> getPopular(int page) async {
    final res = (await client.get(Uri.parse("$baseUrl/videos/trending?page_id=$page"))).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(Uri.parse("$baseUrl/videos/latest?page_id=$page"))).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res =
        (await client.get(
          Uri.parse("$baseUrl/search?keyword=${query.replaceAll(" ", "+")}&page_id=$page"),
        )).body;
    return animeFromElement(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl${url}"))).body;
    MManga anime = MManga();
    final description = xpath(res, '//pre/span/text()');
    if (description.isNotEmpty) {
      anime.description = description.first;
    }
      // Chapter setup
    final onclickValues = xpath(res, '//a[@class="hidden-button buttonDownloadnew"]/@onclick');
    String? finalUrl;
  
    if (onclickValues.isNotEmpty) {
      String onclick = onclickValues.first.replaceAll("&amp;", "&"); // decode HTML entity
      finalUrl = substringAfter(onclick, "url=");
      if (finalUrl.contains("'")) {
        finalUrl = substringBefore(finalUrl, "'");
      }
    }

    anime.status = MStatus.finished; // Default status, can be changed based on actual data

    MChapter watch = MChapter();
    watch.name = "Watch";
    watch.url = finalUrl ?? "";
    watch.episodeNumber = 0.0;
    watch.chapterNumber = 0.0;

    anime.chapters = [watch];
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {

    List<MVideo> videos = [];
  
    for (url.isNotEmpty) {
      MVideo video = MVideo();
      video
        ..url = url
        ..originalUrl = url
        ..quality = "Direct";
      videos.add(video);
    }
  
    return videos;
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [
      EditTextPreference(
        key: "pref_domain_new",
        title: "Currently used domain",
        summary: "",
        value: "https://fibwatch.art",
        dialogTitle: "Currently used domain",
        dialogMessage: "",
        text: "https://fibwatch.art",
      ),
    ];
  }


  MPages animeFromElement(String res) {
    List<MManga> animeList = [];
    final urls = xpath(res, '//*[@class="video-thumb"]/a/@href');
    final names = xpath(res, '//*[@class="channel_details"]/p[@class="hptag"]/@title');
    final images = xpath(res, '//*[@class="video-thumb"]/a/img/@src');

    for (var i = 0; i < names.length; i++) {
      MManga anime = MManga();
      anime.name = names[i].replaceAll("Download", "");
      anime.imageUrl = images[i];
      anime.link = urls[i];
      animeList.add(anime);
    }
    final nextPage = xpath(res, '//a[@title="Next Page"]/@href');
    return MPages(animeList, nextPage.isNotEmpty);
  }


}

FibWatch main(MSource source) {
  return FibWatch(source: source);
}
