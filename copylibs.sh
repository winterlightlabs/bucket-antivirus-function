#/bin/bash
set -e

# We would expect the output from lld to be something like this
# /bin/clamscan:
#	  linux-vdso.so.1 (0x00007ffdf8967000)
#	  libclamav.so.9 => /opt/app/bin/libclamav.so.9 (0x00007ff814aa9000)
#	  libc.so.6 => /opt/app/bin/libc.so.6 (0x00007ff8148a1000)
# We want to strip this down just the file paths so we can copy those over
# 1. Removed things that don't have .so (ie they aren't libraries)
# 2. Stripe whitespace
# 3. Remove => and everything before it
# 4. Remove the hexcodes in brackets
# 5. Sort each line
# 6. Remove duplicates
# 7. Copy everything other than linux-vdso.so.1 into /opt/app/bin
ldd /bin/clamscan /bin/freshclam /bin/ld | grep "\.so" | sed -e 's/\t//' | sed -e 's/.*=>.//' | sed -e 's/ (0.*)//' | sort | uniq | while read LIB;
do
  case $LIB in
    "linux-vdso.so.1")
      echo "Skipping $LIB"
      # linux-vdso.so.1 is not a normal file
    ;;
    *)
      echo $LIB
      cp $LIB /opt/app/bin
    ;;
  esac
done
