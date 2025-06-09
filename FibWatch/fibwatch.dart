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
    final res = (await client.get(
      Uri.parse("$baseUrl/videos/trending?page_id=$page"),
    )).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    final res = (await client.get(
      Uri.parse("$baseUrl/videos/latest?page_id=$page"),
    )).body;
    return animeFromElement(res);
  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    final res = (await client.get(
      Uri.parse(
        "$baseUrl/search?keyword=${query.replaceAll(" ", "+")}&page_id=$page",
      ),
    )).body;
    return animeFromElement(res);
  }

  @override
  Future<MManga> getDetail(String url) async {
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl${url}"))).body;
    MManga anime = MManga();
    final description = xpath(
      res,
      '//p[@class="hptag" and @itemprop="title"]/text()',
    );
    if (description.isNotEmpty) {
      anime.description = description.first;
    }
    anime.status = MStatus.ongoing;
    final episodesTitles = ["Watch"];
    final episodesUrls = [baseUrl + url];
    bool isSeries = false;
    if (episodesTitles.first.contains("Episode") ||
        episodesTitles.first.contains("Zip") ||
        episodesTitles.first.contains("Pack")) {
      isSeries = true;
    }
    List<MChapter>? episodesList = [];
    if (!isSeries) {
      List<String> moviesTitles = ["Watch"];
      moviesTitles = xpath(
        res,
        '//p[@class="hptag" and @itemprop="title"]/text()',
      );
      List<String> titles = [];
      if (moviesTitles.isEmpty) {
        moviesTitles = xpath(res, '//p[contains(@style, "center")]/text()');
      }
      for (var title in moviesTitles) {
        if (title.isNotEmpty &&
            !title.contains('Download') &&
            !title.contains('Note:') &&
            !title.contains('Copyright')) {
          titles.add(title.split('[').first.trim());
        }
      }
      for (var i = 0; i < titles.length; i++) {
        final title = titles[i];
        final quality = RegExp(r'\d{3,4}p').firstMatch(title)?.group(0) ?? "";
        final url = episodesUrls[i];
        MChapter ep = MChapter();
        ep.name = title;
        ep.url = url;
        ep.scanlator = quality;
        episodesList.add(ep);
      }
    } else {
      List<String> seasonTitles = [];
      final episodeTitles = xpath(
        res,
        '//p[@class="hptag" and @itemprop="title"]/text()',
      );
      List<String> titles = [];
      for (var title in episodeTitles) {
        if (title.isNotEmpty) {
          titles.add(title.split('[').first.trim());
        }
      }
      int number = 0;
      for (var i = 0; i < episodesTitles.length; i++) {
        final episode = episodesTitles[i];
        final episodeUrl = episodesUrls[i];
        if (!episode.contains("Zip") || !episode.contains("Pack")) {
          if (episode == "Episode 1" && seasonTitles.contains("Episode 1")) {
            number++;
          } else if (episode == "Episode 1") {
            seasonTitles.add(episode);
          }
          final season =
              RegExp(r'S(\d{2})').firstMatch(titles[number])?.group(1) ?? "";
          final quality =
              RegExp(r'\d{3,4}p').firstMatch(titles[number])?.group(0) ?? "";
          MChapter ep = MChapter();
          ep.name = "Season $season $episode $quality";
          ep.url = episodeUrl;
          ep.scanlator = quality;
          episodesList.add(ep);
        }
      }
    }
    anime.chapters = episodesList.reversed.toList();
    return anime;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    List<MVideo> videos = [];
    // Chapter setup
    url = getUrlWithoutDomain(url);
    final res = (await client.get(Uri.parse("$baseUrl${url}"))).body;
    final onclickValues = xpath(
      res,
      '//a[@class="hidden-button buttonDownloadnew"]/@onclick',
    );
    String? finalUrl;

    if (onclickValues.isNotEmpty) {
      String onclick = onclickValues.first.replaceAll(
        "&amp;",
        "&",
      ); // decode HTML entity
      finalUrl = substringAfter(onclick, "url=");
      if (finalUrl.contains("'")) {
        finalUrl = substringBefore(finalUrl, "'");
        url = finalUrl;
      }
    }

    if (url.isNotEmpty) {
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
    final names = xpath(
      res,
      '//*[@class="channel_details"]/p[@class="hptag"]/@title',
    );
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
