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

    # The npm package ships a small helper for Apple's on-device model, built for Apple silicon.
    # Rebuild it from the Swift source beside it when this Mac's SDK can (the source needs the
    # macOS 27 SDK), keep it as shipped when it cannot, and remove it on Intel, where it cannot run.
    helper_dir = libexec/"lib/node_modules/onionskin-cli/scripts/rewriter/apple"
    helper = helper_dir/"onionskin-fm"
    record_file = helper_dir/"onionskin-fm.json"
    if Hardware::CPU.arm?
      target = "arm64-apple-macos26.0"
      built = buildpath/"onionskin-fm.built"
      if quiet_system "swiftc", "-O", "-parse-as-library", "-target", target, helper_dir/"main.swift", "-o", built
        rm helper
        cp built, helper
        chmod 0755, helper
        record = { file: "onionskin-fm", target:, size: helper.size, sha256: helper.sha256 }
        record_file.atomic_write "#{JSON.pretty_generate(record)}\n"
      end
    else
      rm [helper, record_file]
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
