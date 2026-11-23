class NhcPpCli < Formula
  desc "National Hurricane Center storms, advisories and outlooks for agents"
  homepage "https://github.com/abe238/nhc-pp-cli"
  url "https://github.com/abe238/nhc-pp-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "8afe26f4502aaf0a5535eb627ba47b58cb5ff8df7e9859794d24e1b0833a91d5"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    cli_ldflags = "-s -w -X github.com/abe238/nhc-pp-cli/internal/cli.version=#{version}"
    system "go", "build", *std_go_args(ldflags: cli_ldflags), "./cmd/nhc-pp-cli"
    mcp_ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags: mcp_ldflags, output: bin/"nhc-pp-mcp"), "./cmd/nhc-pp-mcp"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nhc-pp-cli --version")
  end
end
