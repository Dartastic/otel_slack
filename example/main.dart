// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_slack/otel_slack.dart';

/// Traces Slack Web calls with OpenTelemetry.
///
/// `otel_slack` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Slack Web call in
/// [tracedSlackApi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'slack-example');

  // Wraps a Slack Web API method call (chat.postMessage, conversations.history, users.info, etc.) in a CLIENT span.
  final slackApiId = await tracedSlackApi<String>(
    method: 'POST',
    teamId: 'team_8f3a2c',
    channelId: 'channel_8f3a2c',
    ts: 'example',
    invoke: () async {
      // Make the Slack Web call here, then report what it returned.
      return 'slack_8f3a2c';
    },
  );
  OTelLog.info('tracedSlackApi returned $slackApiId');

  // Wraps a Slack Incoming Webhook POST in a PRODUCER span.
  final slackWebhookId = await tracedSlackWebhook<String>(
    payloadSize: 512,
    blockCount: 3,
    invoke: () async {
      // Make the Slack Web call here, then report what it returned.
      return 'slack_8f3a2c';
    },
  );
  OTelLog.info('tracedSlackWebhook returned $slackWebhookId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSlackInstrumentationAsync.
  await runWithoutSlackInstrumentationAsync(
    () => tracedSlackApi<String>(
      method: 'POST',
      teamId: 'team_8f3a2c',
      channelId: 'channel_8f3a2c',
      ts: 'example',
      invoke: () async {
        return 'slack_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
