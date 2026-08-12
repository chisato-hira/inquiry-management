# Rails.error.reportはサブスクライバーが1件も登録されていないと何も記録せず握りつぶすだけになるため、
# 最低限ログに残す購読者を登録しておく。将来Sentry等を導入する際は、ここに購読者を追加すればよい。
class ApplicationErrorLogSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    Rails.logger.error(
      "[ErrorReporter] severity=#{severity} handled=#{handled} #{error.class}: #{error.message} context=#{context.inspect}"
    )
  end
end

Rails.error.subscribe(ApplicationErrorLogSubscriber.new)
