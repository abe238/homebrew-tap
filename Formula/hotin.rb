class Hotin < Formula
  include Language::Python::Virtualenv

  desc "See what is hot in AI from GitHub, Hacker News, npm and Reddit"
  homepage "https://hotin.ai"
  url "https://files.pythonhosted.org/packages/c1/49/889169a6d933d405483ed2341aa5867f51fe70c0c7ce89876a6ba0dd5707/hotin-0.9.21.tar.gz"
  sha256 "2e738789228d5bf07f59df845d2f6900fbaec0ae2eb158e52ef9f4548401822b"
  license "Apache-2.0"

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match "What's hot in AI", shell_output("#{bin}/hotin --help")
  end
end
