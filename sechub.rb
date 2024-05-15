class Sechub < Formula
    desc "CLI tool to update notes in AWS Security Hub"
    homepage "https://github.com/omarnour14/sechub"  # Update with your actual project URL
    url "https://github.com/omarnour14/sechub/archive/v1.0.0.tar.gz"  # URL to the tar.gz of the release
    sha256 "the_SHA256_sum_of_the_tarball"  # Generate this with `shasum -a 256 filename`
  
    def install
      bin.install "sechub"
    end
  
    test do
      system "#{bin}/sechub", "--version"  # Replace with a command that verifies installation
    end
  end
  