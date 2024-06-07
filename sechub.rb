class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.3.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "5ada6b1013d392a1115756b2742db1376baa60ba7f558b8b9fdb1e80a06a5034"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "./sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  