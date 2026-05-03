import 'dart:convert';
import 'dart:io';

const String host = 'localhost';
const int port = 3005;
const String path = '/socket.io/';

Future<void> main() async {
  stdout.writeln('Running raw polling smoke check against http://$host:$port');

  final bool rawOk = await _runRawPollingCheck();

  if (!rawOk) {
    stderr.writeln('Polling smoke failed: raw=$rawOk');
    exit(1);
  }

  stdout.writeln('Polling smoke passed');
}

Future<bool> _runRawPollingCheck() async {
  stdout.writeln('1) Raw Engine.IO polling check');
  final HttpClient client = HttpClient();

  try {
    final HttpClientRequest openReq = await client.getUrl(Uri.parse(
      'http://$host:$port$path?EIO=4&transport=polling&t=${DateTime.now().millisecondsSinceEpoch}',
    ));
    final HttpClientResponse openRes = await openReq.close();
    if (openRes.statusCode != 200) return false;
    final String openData = await openRes.transform(utf8.decoder).join();

    final Match? sidMatch = RegExp(r'"sid":"([^"]+)"').firstMatch(openData);
    if (sidMatch == null) return false;
    final String sid = sidMatch.group(1)!;

    final HttpClientRequest connectReq = await client.postUrl(
      Uri.parse('http://$host:$port$path?EIO=4&transport=polling&sid=$sid'),
    );
    connectReq.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
    connectReq.write('40');
    final HttpClientResponse connectRes = await connectReq.close();
    if (connectRes.statusCode != 200) return false;
    await connectRes.drain<void>();

    final HttpClientRequest eventReq = await client.postUrl(
      Uri.parse('http://$host:$port$path?EIO=4&transport=polling&sid=$sid'),
    );
    eventReq.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
    eventReq.write('42["msg","hello from raw polling"]');
    final HttpClientResponse eventRes = await eventReq.close();
    if (eventRes.statusCode != 200) return false;
    await eventRes.drain<void>();

    final HttpClientRequest pollReq = await client.getUrl(Uri.parse(
      'http://$host:$port$path?EIO=4&transport=polling&sid=$sid&t=${DateTime.now().millisecondsSinceEpoch}',
    ));
    final HttpClientResponse pollRes = await pollReq.close();
    if (pollRes.statusCode != 200) return false;
    final String pollData = await pollRes.transform(utf8.decoder).join();

    final bool ok = pollData.contains('fromServer') || pollData.contains('Message received');
    stdout.writeln('   raw result: $ok');
    return ok;
  } catch (error) {
    stderr.writeln('   raw check error: $error');
    return false;
  } finally {
    client.close(force: true);
  }
}
