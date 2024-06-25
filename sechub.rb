class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/homebrew-sechub"  # Update with your actual project URL
    url "https://github.com/OmarNour14/homebrew-sechub/archive/refs/tags/v1.6.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "b37534080830f6d7ef18993ef2635db9030fd9a279551bdc32153cf5dca4f749"  # Generate this with `shasum -a 256 filename`
  
    def install
        bin.install "./sechub.sh" => "sechub"
      end
  
    test do
      system "#{bin}/sechub", "--help"  # Replace with a command that verifies installation
    end
  end
  