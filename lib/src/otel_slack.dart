// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_slack_suppression.dart';

const _tracerName = 'dartastic_otel_libs_slack';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

/// Wraps a Slack Web API method call (chat.postMessage,
/// conversations.history, users.info, etc.) in a CLIENT span.
Future<T> tracedSlackApi<T>({
  required String method,
  required Future<T> Function() invoke,
  String? teamId,
  String? channelId,
  String? ts,
}) async {
  if (slackInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'slack.method': method,
  };
  if (teamId != null) m['slack.team.id'] = teamId;
  if (channelId != null) m['slack.channel.id'] = channelId;
  if (ts != null) m['slack.message.ts'] = ts;

  final span = _tracer().startSpan(
    'slack $method',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Slack Incoming Webhook POST in a PRODUCER span.
Future<T> tracedSlackWebhook<T>({
  required Future<T> Function() invoke,
  int? payloadSize,
  int? blockCount,
}) async {
  if (slackInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'messaging.system': 'slack_webhook',
    'messaging.operation': 'publish',
    'messaging.destination.name': 'slack_webhook',
  };
  if (payloadSize != null) m['messaging.message.body.size'] = payloadSize;
  if (blockCount != null) m['slack.block.count'] = blockCount;

  final span = _tracer().startSpan(
    'slack webhook',
    kind: SpanKind.producer,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
