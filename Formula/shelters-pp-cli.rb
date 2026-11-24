class SheltersPpCli < Formula
  desc "Find open FEMA and Red Cross emergency shelters, for agents"
  homepage "https://github.com/abe238/shelters-pp-cli"
  url "https://github.com/abe238/shelters-pp-cli/archive/refs/tags/v1.3.0.tar.gz"
  sha256 "e1d1fef20c3a39411480e39a4c3dc7bd217f69bbf6e6369a276f730f3045d545"
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
