# Original version from homebrew-science, updated by namore to make it
# 2021: work with Version 2.17 on MacOS Big Sur and with M1 CPUs (which require GCC 11 or later)
# 2025/01: fixed build for Macos 15 Sequoia
# 2026/03: updated to Version 2.23

class CalculixCcx < Formula
  desc "Three-Dimensional Finite Element Solver"
  homepage "https://www.calculix.de/"
  url "https://www.dhondt.de/ccx_2.23.src.tar.bz2"
  version "2.23"
  sha256 "9c88385c10fb04f5dc6c4e98027a51bebdd8aee3920e05190d6c1dd08357d6e7"

  depends_on "pkg-config" => :build
  depends_on "arpack"
  depends_on "gcc" if OS.mac? # for gfortran
  depends_on "gfortran"

  resource "test" do
    url "https://www.dhondt.de/ccx_2.23.test.tar.bz2"
    version "2.23"
    sha256 "be2259fd9a7b990d0453b30708e1b05f2cd4b6df4a90fa96f0e4abd1ae7beaa0"
  end

  resource "doc" do
    url "https://www.dhondt.de/ccx_2.23.htm.tar.bz2"
    version "2.23"
    sha256 "ed14b31b51972d5492209a42fcd52a062e36cbc7843bcd358617cb3aee0da736"
  end

  resource "spooles" do
    # The spooles library is not currently maintained and so would not make a
    # good brew candidate. Instead it will be static linked to ccx.
    url "http://www.netlib.org/linalg/spooles/spooles.2.2.tgz"
    sha256 "a84559a0e987a1e423055ef4fdf3035d55b65bbe4bf915efaa1a35bef7f8c5dd"
  end

  def install
    (buildpath/"spooles").install resource("spooles")

    # Patch spooles library
    inreplace "spooles/Make.inc", "/usr/lang-4.0/bin/cc", ENV.cc
    inreplace "spooles/Make.inc", "CFLAGS = $(OPTLEVEL)", "CFLAGS = $(OPTLEVEL) -Wno-error=int-conversion"
    inreplace "spooles/Tree/src/makeGlobalLib", "drawTree.c", "tree.c"

    # Build serial spooles library
    system "make", "-C", "spooles", "lib"

    # Extend library with multi-threading (MT) subroutines
    system "make", "-C", "spooles/MT/src", "makeLib"

    source_dir = buildpath/"ccx_2.23"/"src"
    makefile = source_dir/"Makefile"
    inreplace source_dir/"readnewmesh.c",
              "*iprfnp=iprfn;*konrfnp=konrfn;*ratiorfnp=ratiorfn;\n  \n  return NULL;\n",
              "*iprfnp=iprfn;*konrfnp=konrfn;*ratiorfnp=ratiorfn;\n  \n  return;\n"
    inreplace makefile, "FFLAGS = -Wall -O2 -cpp ", "FFLAGS = -std=legacy -O2 -cpp "
    inreplace makefile, "ccx_2.23: $(OCCXMAIN) ccx_2.23.a  $(LIBS)", "ccx_2.23: $(OCCXMAIN) ccx_2.23.a"

    # Build Calculix ccx
    cflags = %w[-O2 -Wno-error=implicit-function-declaration -I../../spooles -DARCH=Linux -DSPOOLES -DARPACK
                -DMATRIXSTORAGE]
    libs = ["$(DIR)/spooles.a", "$(shell pkg-config --libs arpack)"]
    # ARPACK uses Accelerate on macOS
    libs << "-framework accelerate"
    args = ["CC=#{ENV.cc}",
            "FC=gfortran",
            "CFLAGS=#{cflags.join(" ")}",
            "DIR=../../spooles",
            "LIBS=#{libs.join(" ")}"]
    target = source_dir/"ccx_2.23"
    system "make", "-C", source_dir, target.basename, *args
    bin.install target

    (buildpath/"test").install resource("test")
    pkgshare.install Dir["test/**/ccx_2.23/test/*"]

    (buildpath/"doc").install resource("doc")
    doc.install Dir["doc/**/ccx_2.23/doc/ccx/*"]
  end

  test do
    cp "#{pkgshare}/spring1.inp", testpath
    system "#{bin}/ccx_2.23", "spring1"
  end
end
