require "test_helper"

class InquiriesRateLimitTest < ActionDispatch::IntegrationTest
  setup do
    # テスト環境の config.cache_store は :null_store のため、
    # Rack::Attackのスロットリングカウントを実際に保持できるストアに差し替える
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.enabled = false
  end

  test "POST /inquiriesは同一IPから1分間に5回を超えると429になる" do
    5.times do
      post inquiries_url, params: { inquiry: valid_inquiry_params }
      assert_response :created
    end

    post inquiries_url, params: { inquiry: valid_inquiry_params }

    assert_response 429
    assert_includes JSON.parse(response.body)["error"], "多すぎます"
  end

  private

  def valid_inquiry_params
    {
      name: "山田太郎",
      email: "yamada@example.com",
      phone: "090-1234-5678",
      category: "不具合",
      content: "画面が表示されません"
    }
  end
end
