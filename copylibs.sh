#/bin/bash
set -e

ldd /bin/clamscan /bin/freshclam /bin/ld | grep so | sed -e '/^[^\t]/ d' | sed -e 's/\t//' | sed -e 's/.*=..//' | sed -e 's/ (0.*)//' | sort | uniq | while read LIB;
do
  case $LIB in
    "linux-vdso.so.1")
      echo "Skipping $LIB"
    ;;
    *)
      echo $LIB
      cp $LIB /opt/app/bin
    ;;
  esac
done
