class Realstop < Formula
  include Language::Python::Virtualenv

  desc "Stop hook that catches coding agents handing back unfinished work"
  homepage "https://decisiontune.com/realstop/"
  url "https://files.pythonhosted.org/packages/fc/be/d7bd905ed454619afabbd9819c92f2a8718623cbb9d9754acb5a7462c4f1/realstop-0.2.2.tar.gz"
  sha256 "b50e3af6f186009fa37dd596cb7c16544debb09097955b54b4a8de460ce61981"
  license "Apache-2.0"

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  def caveats
    <<~EOS
      To add the hook to Claude Code, run:
        realstop setup
      After `brew upgrade realstop`, run it again to refresh the hook files.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/realstop --version")
  end
end
