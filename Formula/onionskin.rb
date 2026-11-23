class Onionskin < Formula
  desc "Review and edit Office, HTML and Markdown files with a coding agent"
  homepage "https://onionskin.abediaz.ai"
  url "https://registry.npmjs.org/onionskin-cli/-/onionskin-cli-1.0.3.tgz"
  sha256 "106f0d2880cf2ed4507eb80a1cf516200510e3a37561291bc61fabbeec43cc5a"
  license "MIT"

  depends_on :macos
  depends_on "node"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec.glob("bin/*")

    # The npm package ships a prebuilt helper for Apple's on-device model.
    # Remove it and build it from the Swift source beside it where the SDK allows.
    helper_dir = libexec/"lib/node_modules/onionskin-cli/scripts/rewriter/apple"
    rm [helper_dir/"onionskin-fm", helper_dir/"onionskin-fm.json"]
    if Hardware::CPU.arm? && MacOS.version >= :tahoe
      target = "arm64-apple-macos26.0"
      helper = helper_dir/"onionskin-fm"
      system "swiftc", "-O", "-parse-as-library", "-target", target, helper_dir/"main.swift", "-o", helper
      record = { file: "onionskin-fm", target:, size: helper.size, sha256: helper.sha256 }
      (helper_dir/"onionskin-fm.json").write "#{JSON.pretty_generate(record)}\n"
    end
  end

  def caveats
    <<~EOS
      To install the agent skill for Claude Code and Codex, run:
        onionskin setup
      After `brew upgrade onionskin`, refresh the skill with:
        onionskin setup --force
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/onionskin --version").strip

    (testpath/"page.html").binwrite "<!doctype html><html><head><meta charset=\"windows-1252\">" \
                                    "<title>t</title></head><body><p>caf\xE9</p></body></html>\n"
    system bin/"onionskin", "utf8-copy", testpath/"page.html"
    assert_match "café", (testpath/"page.utf8.html").read

    assert_match "brew upgrade onionskin", shell_output("#{bin}/onionskin update")
  end
end
