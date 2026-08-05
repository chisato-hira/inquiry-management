class StaffsController < ApplicationController
  before_action :require_login

  def index
    # /inquiriesと異なりページネーション不要な小規模データのため、
    # metaラッパーを使わず素の配列で返す(仕様の違いであり実装漏れではない)
    #
    # password_digestを絶対に含めないよう、select段階で除外した上で
    # 手動でJSONを組み立てる(render json: Staff.allのような書き方はしない)
    staffs = Staff.order(:name).select(:id, :name)
    render json: staffs.map { |staff| { id: staff.id, name: staff.name } }
  end
end
