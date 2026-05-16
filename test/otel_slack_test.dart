// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_slack/otel_slack.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_slack-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('chat.postMessage records CLIENT span', () async {
    await tracedSlackApi<String>(
      method: 'chat.postMessage',
      teamId: 'T123',
      channelId: 'C123',
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('slack chat.postMessage')!);
    expect(a['slack.method'], 'chat.postMessage');
    expect(a['slack.team.id'], 'T123');
    expect(a['slack.channel.id'], 'C123');
  });

  test('webhook records PRODUCER span', () async {
    await tracedSlackWebhook<String>(
      payloadSize: 500,
      blockCount: 4,
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('slack webhook');
    expect(span!.kind, SpanKind.producer);
    final a = attrsOf(span);
    expect(a['messaging.system'], 'slack_webhook');
    expect(a['slack.block.count'], 4);
  });

  test('suppression skips spans', () async {
    await runWithoutSlackInstrumentationAsync(() async {
      await tracedSlackApi<String>(
        method: 'auth.test',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('slack '), isEmpty);
  });
}
