import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class BdixICCFtpProvider extends MProvider {
  BdixICCFtpProvider({required this.source});

  @override
  MSource source;

  final Client client = Client();

  String newUrl = "http://10.16.100.244/";

  @override
  Map<String, String> get headers => {};

  @override
  bool get supportsLatest => true;

  @override
  bool get hasCloudflare => false;
  

  @override
  Future<MPages> getPopular(int page) async {
    final categories = [
      {"name": "Latest", "path": "index.php?category=0"},
      {"name": "Bangla Movies", "path": "&category=59"},
      {"name": "Hindi Movies", "path": "&category=2"},
      {"name": "English Movies", "path": "&category=19"},
      {"name": "Dual Audio", "path": "&category=43"},
      {"name": "South Movies", "path": "&category=32"},
      {"name": "Animated", "path": "&category=33"},
      {"name": "English Series", "path": "&category=36"},
      {"name": "Hindi Series", "path": "&category=37"},
      {"name": "Documentary", "path": "&category=41"},
      {"name": "anime", "path": "&category=2"},
      {"name": "bangla series", "path": "&category=34"},
      {"name": "webfilm", "path": "&category=35"},
      {"name": "seanim", "path": "&category=82"},
      {"name": "seanime", "path": "&category=78"},
      {"name": "tele", "path": "&category=39"},
      {"name": "Hindiries", "path": "&category=72"},
      {"name": "DocuSe", "path": "&category=81"},
      {"name": "animeMov", "path": "&category=83"},
      {"name": "English Movies", "path": "&category=60"},
      {"name": "Dual Audio", "path": "&category=43"},
      {"name": "Southes", "path": "&category=73"},
      {"name": "Foed", "path": "&category=64"},
      {"name": "4k", "path": "&category=74"},
      {"name": "fullhd", "path": "&category=44"},
      {"name": "3Documentary", "path": "&category=9"},
    ];

    if (page > 1) return MPages([], false);

    final List<MManga> allItems = [];
    
    bool fiTime = true;

    for (var cat in categories) {

      if (fiTime) {
        final url = "${source.baseUrl}${cat["path"]}";

      } else {
        final url = "${newUrl}${cat["path"]}";
      }
      
      final res = await client.get(Uri.parse(url));

      final document = parseHtml(res.body);

      final elements = document.select("div.post-wrapper > a");
     
      if (fiTime) {
        final Element? logoLink = document.selectFirst("a.logotype");
        final String temdata = logoLink.attr("href");
        newUrl += temdata.substring(0, temdata.length - 11);
        fiTime = false;

        // RegExp regExp = RegExp(r"session=.*?(?=&)");
        // var match = regExp.firstMatch(elements[0].attr("href"));

        // if (match != null) {
        //   print(match);
        //   newUrl += match[0];
        //   filTime = false;
        // }
      }
     
      for (var e in elements) {
        final title = e.selectFirst("img")?.attr("alt")?.trim() ?? "";
        if (title.isEmpty) continue;

        final href = e.attr("href");
        final poster = e.selectFirst("img")?.attr("src");

        final MManga manga = MManga();
        manga.link = "${source.baseUrl}$href";
        manga.name = title;
        if (poster != null && poster.isNotEmpty) {
          manga.imageUrl = "${source.baseUrl}$poster";
        }

        allItems.add(manga);
      }
    }

    return MPages(allItems, false);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    
    final List<MManga> allItems = [];
    final String latestUrl = newUrl + "index.php?category=0";

    final res = await client.get(Uri.parse(latestUrl));
    final document = parseHtml(res.body);

    // Select all the <a> tags inside owl-item (these are the movie cards)
    final elements = document.select(".owl-item a");

    final List<MManga> items = [];

    for (var element in elements) {
      // 1. Get the title
      final String title = element.selectFirst(".title span")?.text()?.trim() ?? "Unknown Title";

      // 2. Get the image URL from background-image
      final String? bgStyle = element.selectFirst(".img")?.attr("style");
      String imageUrl = "";
      if (bgStyle != null && bgStyle.contains("background-image: url('")) {
        final int start = bgStyle.indexOf("url('") + 5;
        final int end = bgStyle.indexOf("')", start);
        if (end != -1) {
          imageUrl = bgStyle.substring(start, end);
          // Make it absolute URL
          if (imageUrl.startsWith("files/")) {
            imageUrl = "${source.baseUrl}$imageUrl";
          }
        }
      }

      // 3. Get the player link (href of the <a>)
      final String href = element.attr("href");
      final String link = href.startsWith("player.php") 
          ? "${source.baseUrl}$href" 
          : href;

      // Create the item
      final MManga manga = MManga();
      manga.name = title;
      manga.link = link;
      manga.imageUrl = imageUrl.isNotEmpty ? imageUrl : null;

      items.add(manga);
    }

    return MPages(items, false);

  }

  @override
  Future<MPages> search(String query, int page, FilterList filterList) async {
    if (query.isEmpty) return MPages([], false);

    final searchUrl = "${source.baseUrl}command.php?cSearch=${Uri.encodeQueryComponent(query)}";

    final res = await client.get(Uri.parse(searchUrl));

    final List<dynamic> jsonData = jsonDecode(res.body);
    final List<MManga> items = [];

    for (var item in jsonData) {
      final map = item as Map<String, dynamic>;
      final id = map["id"]?.toString();
      final name = map["name"]?.toString()?.trim() ?? "";
      final image = map["image"]?.toString();

      if (name.isEmpty || id == null) continue;

      final MManga manga = MManga();
      manga.link = "${source.baseUrl}player.php?play=$id";
      manga.name = name;
      if (image != null && image.isNotEmpty) {
        manga.imageUrl = "${source.baseUrl}files/$image";
      }

      items.add(manga);
    }

    return MPages(items, false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    final res = await client.get(Uri.parse(url));
    final document = parseHtml(res.body);

    final table = document.selectFirst(".table > tbody");
    final title = table?.selectFirst("tr:nth-child(1)")?.text()?.trim() ?? "";
    final yearStr = table?.selectFirst("tr:nth-child(2) > td:nth-child(2)")?.text();
    final year = int.tryParse(yearStr ?? "");

    final genreStr = table?.selectFirst("tr:nth-child(5) > td:nth-child(2)")?.text() ?? "";
    final List<String> genre = [];
    final genreParts = genreStr.split(",");
    for (var part in genreParts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        genre.add(trimmed);
      }
    }

    final description = table?.selectFirst("tr:nth-child(12) > td:nth-child(2)")?.text()?.trim() ?? "";

    final poster = document.selectFirst(".col-md-4 > img")?.attr("src");
    final imageUrl = poster != null && poster.isNotEmpty ? "${source.baseUrl}$poster" : null;

    final downloadItems = document.select(".btn-group > ul > li");

    final List<MChapter> chapters = [];

    if (downloadItems.isEmpty) {
      final link = document.selectFirst("a.btn")?.attr("href");
      if (link != null && link.isNotEmpty) {
        final MChapter chapter = MChapter();
        chapter.name = title.isNotEmpty ? title : "Watch Movie";
        chapter.url = link;
        chapters.add(chapter);
      }
    } else {
      for (var item in downloadItems) {
        final a = item.selectFirst("a");
        final link = a?.attr("href");
        final text = a?.text() ?? "";
        final spanText = item.selectFirst("span")?.text() ?? "";
        final epName = text.replaceAll(spanText, "").trim();

        if (link != null && link.isNotEmpty && epName.isNotEmpty) {
          final MChapter chapter = MChapter();
          chapter.name = epName;
          chapter.url = link;
          chapters.add(chapter);
        }
      }
    }

    final MManga detail = MManga();
    detail.link = url;
    detail.name = title;
    if (imageUrl != null) {
      detail.imageUrl = imageUrl;
    }
    detail.description = description;
    detail.genre = genre;

    // These fields are often expected to be null or empty string, not omitted
    detail.author = null;
    detail.artist = null;
    detail.status = null;

    // year must be set as int? (null allowed)
//detail.year = year;

    detail.chapters = chapters;

    return detail;
  }

  @override
  Future<List<MVideo>> getVideoList(String url) async {
    final List<MVideo> videos = [];
    final MVideo video = MVideo();
    video.url = url;
    video.quality = "Direct Link";
    video.originalUrl = url;
    videos.add(video);
    return videos;
  }

  @override
  Future<List<String>> getPageList(String url) async {
    return [];
  }

  @override
  List<dynamic> getFilterList() {
    return [];
  }

  @override
  List<dynamic> getSourcePreferences() {
    return [];
  }
}

BdixICCFtpProvider main(MSource source) => BdixICCFtpProvider(source: source);
