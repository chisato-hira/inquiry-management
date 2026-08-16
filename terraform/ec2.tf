# --- 最新のAmazon Linux 2023 AMIを検索 ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- SSH用のキーペア(公開鍵をAWSに登録。秘密鍵はローカルの~/.sshに残したまま) ---
resource "aws_key_pair" "deploy" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/inquiry-management-key.pub")
}

# --- EC2インスタンス(nginx:80 + Rails:3000 を同居) ---
resource "aws_instance" "app" {
  # t2.microはこのアカウントでは無料利用枠対象外だったため、対象のt3.microを使用
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deploy.key_name
  subnet_id              = aws_subnet.public_1a.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  # --- CPUクレジットはstandard固定(unlimitedはクレジット超過分が無料枠外の追加課金対象になるため) ---
  credit_specification {
    cpu_credits = "standard"
  }

  # --- ルートボリューム(AMIスナップショットが30GB以上を要求するため30GBに設定。無料枠上限と一致) ---
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  # user_data変更時にインスタンスを再作成する(変更を反映するため)
  user_data_replace_on_change = true

  # --- 起動時セットアップ: Ruby3.4.10(rbenv) / Node.js22 / nginx ---
  user_data = <<-EOF
    #!/bin/bash
    set -ex
    dnf update -y

    # --- スワップ領域を追加(t3.microはメモリ1GBしかなく、Rubyのソースビルド中にOOM Killerで
    #     gccが強制終了する事象が発生したため。ビルド完了後も保持し、実行時のメモリ不足対策も兼ねる) ---
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

    # --- 前提パッケージ・Rubyビルドに必要な開発ツール一式・MySQLクライアントライブラリ(mysql2 gemのビルド用) ---
    dnf groupinstall -y "Development Tools"
    dnf install -y unzip zip tar gzip nginx git \
      openssl-devel readline-devel zlib-devel libyaml-devel \
      libffi-devel bzip2 bzip2-devel gdbm-devel ncurses-devel \
      sqlite-devel mariadb105-devel

    # --- Ruby 3.4.10 (rbenv経由、/opt配下にインストールしec2-userからも参照できるようにする) ---
    # /tmpはtmpfs(メモリ上、約459MBしかない)でビルド中の作業ファイルが溢れるため、
    # ディスク上の/var/tmpをビルド用の一時ディレクトリに指定する
    export TMPDIR=/var/tmp
    export RBENV_ROOT="/opt/rbenv"
    git clone https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
    git clone https://github.com/rbenv/ruby-build.git "$RBENV_ROOT/plugins/ruby-build"
    export PATH="$RBENV_ROOT/bin:$PATH"
    eval "$(rbenv init -)"
    # 並列ビルド(-j2)は1コアあたりのメモリ消費が増えOOMを誘発しやすいため、-j1に固定して安定性を優先する
    export MAKE_OPTS="-j 1"
    RUBY_CONFIGURE_OPTS="--disable-install-doc" rbenv install 3.4.10
    rbenv global 3.4.10
    rbenv exec gem install bundler
    ln -sf "$RBENV_ROOT/shims/ruby" /usr/local/bin/ruby
    ln -sf "$RBENV_ROOT/shims/gem" /usr/local/bin/gem
    ln -sf "$RBENV_ROOT/shims/bundle" /usr/local/bin/bundle
    ln -sf "$RBENV_ROOT/shims/rails" /usr/local/bin/rails
    # bundle install等でec2-userが書き込めるようにする
    chown -R ec2-user:ec2-user "$RBENV_ROOT"

    # --- Node.js 22 (fnm経由、/opt配下にインストール。Vue.jsのフロントエンドビルド用) ---
    export FNM_DIR="/opt/fnm"
    mkdir -p "$FNM_DIR"
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
    export PATH="$FNM_DIR:$PATH"
    eval "$(fnm env)"
    fnm install 22
    FNM_NODE_DIR=$(find "$FNM_DIR" -type d -name "bin" | head -1)
    ln -sf "$FNM_NODE_DIR/node" /usr/local/bin/node
    ln -sf "$FNM_NODE_DIR/npm" /usr/local/bin/npm
    ln -sf "$FNM_NODE_DIR/npx" /usr/local/bin/npx

    # --- nginx起動 ---
    systemctl enable nginx
    systemctl start nginx

    # --- アプリ配置用ディレクトリ ---
    mkdir -p /opt/app
    chown ec2-user:ec2-user /opt/app
  EOF

  tags = {
    Name = "${var.project_name}-app"
  }

  # AMIはmost_recent=trueで検索しているため、AWSが新しいAMIを公開するたびに
  # 「作り直し」が計画されてしまう。動作確認済みのインスタンスを意図せず
  # 再作成しないよう、AMIの変更を無視する
  lifecycle {
    ignore_changes = [ami]
  }
}
