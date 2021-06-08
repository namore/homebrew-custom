# Original version from homebrew-science, updated by namore to make it
# work with Version 2.17 on MacOS Big Sur and with M1 CPUs (which require GCC 11 or later)

class NamoreCalculixCcx < Formula
  desc "Three-Dimensional Finite Element Solver"
  homepage "http://www.calculix.de/"
  url "http://www.dhondt.de/ccx_2.17.src.tar.bz2"
  version "2.17"
  sha256 "ca708ad4aa729d9f84a9faba343c1bcc0b7cc84ed372616ebb55c8e6fa8f6e50"

  depends_on "pkg-config" => :build
  depends_on "arpack"
  depends_on "gfortran"
  depends_on :macos

  resource "test" do
    url "http://www.dhondt.de/ccx_2.17.test.tar.bz2"
    version "2.17"
    sha256 "798f94e536197bb10a74bae096f2a29a5111239020e7d10f93e1ad3d90c370cf"
  end

  resource "doc" do
    url "http://www.dhondt.de/ccx_2.17.htm.tar.bz2"
    version "2.17"
    sha256 "1af8f5e48d5a09637428e69a606fbd21beb719ab3dda9ff8ffed7545e15d6dcc"
  end

  resource "spooles" do
    # The spooles library is not currently maintained and so would not make a
    # good brew candidate. Instead it will be static linked to ccx.
    url "http://www.netlib.org/linalg/spooles/spooles.2.2.tgz"
    sha256 "a84559a0e987a1e423055ef4fdf3035d55b65bbe4bf915efaa1a35bef7f8c5dd"
  end

  patch :DATA

  def install
    (buildpath/"spooles").install resource("spooles")

    # Patch spooles library
    inreplace "spooles/Make.inc", "/usr/lang-4.0/bin/cc", ENV.cc
    inreplace "spooles/Tree/src/makeGlobalLib", "drawTree.c", "tree.c"

    # Build serial spooles library
    system "make", "-C", "spooles", "lib"

    # Extend library with multi-threading (MT) subroutines
    system "make", "-C", "spooles/MT/src", "makeLib"

    # Buid Calculix ccx
    cflags = %w[-O2 -I../../spooles -DARCH=Linux -DSPOOLES -DARPACK -DMATRIXSTORAGE]
    libs = ["$(DIR)/spooles.a", "$(shell pkg-config --libs arpack)"]
    # ARPACK uses Accelerate on macOS
    libs << "-framework accelerate"
    args = ["CC=#{ENV.cc}",
            "FC=gfortran",
            "CFLAGS=#{cflags.join(" ")}",
            "DIR=../../spooles",
            "LIBS=#{libs.join(" ")}"]
    target = Pathname.new("ccx_2.17/src/ccx_2.17")
    system "make", "-C", target.dirname, target.basename, *args
    bin.install target

    (buildpath/"test").install resource("test")
    pkgshare.install Dir["test/ccx_2.17/test/*"]

    (buildpath/"doc").install resource("doc")
    doc.install Dir["doc/ccx_2.17/doc/ccx/*"]
  end

  test do
    cp "#{pkgshare}/spring1.inp", testpath
    system "#{bin}/ccx_2.17", "spring1"
  end
end

# internal version: 0
__END__
diff --git a/ccx_2.17/src/Makefile b/ccx_2.17/src/Makefile
index 97ce9d1..632a617 100755
--- a/ccx_2.17/src/Makefile
+++ b/ccx_2.17/src/Makefile
@@ -1,6 +1,6 @@
 
 CFLAGS = -Wall -O2  -I ../../../SPOOLES.2.2 -DARCH="Linux" -DSPOOLES -DARPACK -DMATRIXSTORAGE -DNETWORKOUT
-FFLAGS = -Wall -O2
+FFLAGS = -std=legacy -O2
 
 CC=cc
 FC=gfortran
@@ -25,8 +25,8 @@ LIBS = \
 	../../../ARPACK/libarpack_INTEL.a \
        -lpthread -lm -lc
 
-ccx_2.17: $(OCCXMAIN) ccx_2.17.a  $(LIBS)
-	./date.pl; $(CC) $(CFLAGS) -c ccx_2.17.c; $(FC)  -Wall -O2 -o $@ $(OCCXMAIN) ccx_2.17.a $(LIBS)
+ccx_2.17: $(OCCXMAIN) ccx_2.17.a
+	./date.pl; $(CC) $(CFLAGS) -c ccx_2.17.c; $(FC) $(FFLAGS) -o $@ $(OCCXMAIN) ccx_2.17.a $(LIBS)
 
 ccx_2.17.a: $(OCCXF) $(OCCXC)
 	ar vr $@ $?
