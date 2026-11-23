class SheltersPpCli < Formula
  desc "Find open FEMA and Red Cross emergency shelters, for agents"
  homepage "https://github.com/abe238/shelters-pp-cli"
  url "https://github.com/abe238/shelters-pp-cli/archive/refs/tags/v1.3.1.tar.gz"
  sha256 "b94ae5b96af1995411c368fc9baab42bdddb91222a583cd1aed0df040c1d161c"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    ENV["CGO_ENABLED"] = "0"
    cli_ldflags = "-s -w -X github.com/abe238/shelters-pp-cli/internal/cli.version=#{version}"
    system "go", "build", *std_go_args(ldflags: cli_ldflags), "./cmd/shelters-pp-cli"
    mcp_ldflags = "-s -w -X main.version=#{version}"
    system "go", "build", *std_go_args(ldflags: mcp_ldflags, output: bin/"shelters-pp-mcp"), "./cmd/shelters-pp-mcp"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/shelters-pp-cli --version")
  end
end
